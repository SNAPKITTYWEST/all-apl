use serde::{Serialize, Deserialize};
use sha2::{Sha256, Digest};


#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamChunk {
    pub id: String,
    pub items: Vec<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamResult {
    pub chunk_id: String,
    pub closed: Vec<serde_json::Value>,
    pub failed: Vec<serde_json::Value>,
    pub elapsed_ms: f64,
    pub seal: String,
}

pub struct MantraQConfig {
    pub chunk_size: usize,
    pub parallelism: usize,
    pub timeout_ms: u64,
}

impl Default for MantraQConfig {
    fn default() -> Self {
        MantraQConfig { chunk_size: 1000, parallelism: 4, timeout_ms: 5000 }
    }
}

pub struct StrategyChain;

impl StrategyChain {
    pub fn new() -> Self { StrategyChain }

    pub fn close(&self, item: &serde_json::Value) -> Option<serde_json::Value> {
        let patterns = item.get("patterns").and_then(|p| p.as_array())?;
        let has_sum = patterns.iter().any(|p| p.get("type").and_then(|t| t.as_str()) == Some("sum"));
        let power_val = patterns.iter().find_map(|p| {
            if p.get("type").and_then(|t| t.as_str()) == Some("power") {
                p.get("value").and_then(|v| v.as_i64())
            } else { None }
        });

        let n = item.get("n").and_then(|v| v.as_i64()).unwrap_or(10);

        if has_sum {
            if let Some(2) = power_val {
                let result = n * (n + 1) * (2 * n + 1) / 6;
                return Some(serde_json::json!({"result": result, "strategy": "ffi_kernel", "classification": "sumsquares"}));
            }
            if let Some(3) = power_val {
                let s = n * (n + 1) / 2;
                return Some(serde_json::json!({"result": s * s, "strategy": "ffi_kernel", "classification": "sumcubes"}));
            }
            let result = n * (n + 1) / 2;
            return Some(serde_json::json!({"result": result, "strategy": "ffi_kernel", "classification": "sumlinear"}));
        }
        None
    }
}

pub struct MantraQStream {
    pub config: MantraQConfig,
    chain: StrategyChain,
    buffer: Vec<serde_json::Value>,
}

impl MantraQStream {
    pub fn new(config: MantraQConfig) -> Self {
        MantraQStream { config, chain: StrategyChain::new(), buffer: vec![] }
    }

    pub fn ingest(&mut self, items: Vec<serde_json::Value>) -> Vec<StreamResult> {
        self.buffer.extend(items);
        let mut results = vec![];
        while self.buffer.len() >= self.config.chunk_size {
            let chunk: Vec<_> = self.buffer.drain(..self.config.chunk_size).collect();
            results.push(self.process_chunk(chunk));
        }
        results
    }

    pub fn flush(&mut self) -> Vec<StreamResult> {
        if !self.buffer.is_empty() {
            let chunk: Vec<_> = self.buffer.drain(..).collect();
            vec![self.process_chunk(chunk)]
        } else {
            vec![]
        }
    }

    fn process_chunk(&self, items: Vec<serde_json::Value>) -> StreamResult {
        let start = std::time::Instant::now();
        let mut closed = vec![];
        let mut failed = vec![];
        for item in items {
            match self.chain.close(&item) {
                Some(result) => closed.push(serde_json::json!({"item": item, "proof": result})),
                None => failed.push(item),
            }
        }
        let elapsed = start.elapsed().as_secs_f64() * 1000.0;
        let seal_data = serde_json::json!({"closed": closed.len(), "failed": failed.len(), "elapsed_ms": elapsed});
        let mut hasher = Sha256::new();
        hasher.update(serde_json::to_string(&seal_data).unwrap().as_bytes());
        let seal = format!("{:x}", hasher.finalize());
        StreamResult {
            chunk_id: seal[..16].to_string(),
            closed, failed, elapsed_ms: elapsed, seal,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strategy_chain_sumsquares() {
        let chain = StrategyChain::new();
        let item = serde_json::json!({"patterns": [{"type": "sum"}, {"type": "power", "value": 2}], "n": 10});
        let r = chain.close(&item).unwrap();
        assert_eq!(r["result"], 385); // 10*11*21/6
    }

    #[test]
    fn test_strategy_chain_sumlinear() {
        let chain = StrategyChain::new();
        let item = serde_json::json!({"patterns": [{"type": "sum"}], "n": 10});
        let r = chain.close(&item).unwrap();
        assert_eq!(r["result"], 55); // 10*11/2
    }

    #[test]
    fn test_mantraq_stream() {
        let mut stream = MantraQStream::new(MantraQConfig { chunk_size: 5, ..Default::default() });
        let items: Vec<_> = (0..12).map(|i| serde_json::json!({"patterns": [{"type": "sum"}], "n": i + 1})).collect();
        let mut results = stream.ingest(items);
        results.extend(stream.flush());
        assert!(!results.is_empty());
        let total_closed: usize = results.iter().map(|r| r.closed.len()).sum();
        assert!(total_closed > 0);
    }
}
