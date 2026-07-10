use std::collections::HashMap;
use std::env;
use std::fs;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: rexx <script.rexx>");
        std::process::exit(1);
    }

    let filename = &args[1];
    let source = fs::read_to_string(filename).unwrap_or_else(|e| {
        eprintln!("Error reading {}: {}", filename, e);
        std::process::exit(1);
    });

    let mut interp = Interpreter::new();
    match interp.run(&source) {
        Ok(()) => {}
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}

#[derive(Debug, Clone)]
enum Value {
    Str(String),
    Num(f64),
    Bool(bool),
}

impl Value {
    fn to_str(&self) -> String {
        match self {
            Value::Str(s) => s.clone(),
            Value::Num(n) => {
                if *n == (*n as i64) as f64 {
                    format!("{}", *n as i64)
                } else {
                    format!("{}", n)
                }
            }
            Value::Bool(b) => if *b { "1" } else { "0" }.to_string(),
        }
    }

    fn to_num(&self) -> f64 {
        match self {
            Value::Num(n) => *n,
            Value::Str(s) => s.parse().unwrap_or(0.0),
            Value::Bool(b) => if *b { 1.0 } else { 0.0 },
        }
    }

    fn is_true(&self) -> bool {
        match self {
            Value::Bool(b) => *b,
            Value::Num(n) => *n != 0.0,
            Value::Str(s) => !s.is_empty() && s != "0",
        }
    }
}

#[derive(Debug, Clone)]
enum Token {
    Say,
    Parse,
    Arg,
    Var,
    If,
    Then,
    Else,
    Do,
    End,
    To,
    By,
    While,
    Until,
    Leave,
    Iterate,
    Exit,
    Return,
    Call,
    Procedure,
    Expose,
    Select,
    When,
    Otherwise,
    NOP,
    Identifier(String),
    String(String),
    Number(f64),
    LParen,
    RParen,
    Comma,
    Semi,
    Eq,
    Neq,
    Lt,
    Gt,
    Leq,
    Geq,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    And,
    Or,
    Not,
    Concat,
    Dot,
    EOF,
}

struct Lexer {
    chars: Vec<char>,
    pos: usize,
}

impl Lexer {
    fn new(source: &str) -> Self {
        Lexer {
            chars: source.chars().collect(),
            pos: 0,
        }
    }

    fn peek(&self) -> Option<char> {
        self.chars.get(self.pos).copied()
    }

    fn next(&mut self) -> Option<char> {
        let c = self.chars.get(self.pos).copied();
        self.pos += 1;
        c
    }

    fn skip_whitespace(&mut self) {
        while let Some(c) = self.peek() {
            if c.is_whitespace() {
                self.next();
            } else if c == '/' && self.pos + 1 < self.chars.len() && self.chars[self.pos + 1] == '*' {
                self.next();
                self.next();
                while let Some(c) = self.peek() {
                    self.next();
                    if c == '*' && self.peek() == Some('/') {
                        self.next();
                        break;
                    }
                }
            } else {
                break;
            }
        }
    }

    fn tokenize(&mut self) -> Vec<Token> {
        let mut tokens = Vec::new();
        loop {
            self.skip_whitespace();
            match self.peek() {
                None => {
                    tokens.push(Token::EOF);
                    break;
                }
                Some('(') => { self.next(); tokens.push(Token::LParen); }
                Some(')') => { self.next(); tokens.push(Token::RParen); }
                Some(',') => { self.next(); tokens.push(Token::Comma); }
                Some(';') => { self.next(); tokens.push(Token::Semi); }
                Some('+') => { self.next(); tokens.push(Token::Plus); }
                Some('*') => { self.next(); tokens.push(Token::Star); }
                Some('/') => { self.next(); tokens.push(Token::Slash); }
                Some('%') => { self.next(); tokens.push(Token::Percent); }
                Some('.') => { self.next(); tokens.push(Token::Dot); }
                Some('=') => {
                    self.next();
                    if self.peek() == Some('=') {
                        self.next();
                        tokens.push(Token::Eq);
                    } else {
                        tokens.push(Token::Eq);
                    }
                }
                Some('~') => {
                    self.next();
                    if self.peek() == Some('=') {
                        self.next();
                        tokens.push(Token::Neq);
                    } else {
                        tokens.push(Token::Not);
                    }
                }
                Some('<') => {
                    self.next();
                    if self.peek() == Some('=') {
                        self.next();
                        tokens.push(Token::Leq);
                    } else if self.peek() == Some('>') {
                        self.next();
                        tokens.push(Token::Neq);
                    } else {
                        tokens.push(Token::Lt);
                    }
                }
                Some('>') => {
                    self.next();
                    if self.peek() == Some('=') {
                        self.next();
                        tokens.push(Token::Geq);
                    } else {
                        tokens.push(Token::Gt);
                    }
                }
                Some('|') => {
                    self.next();
                    tokens.push(Token::Concat);
                }
                Some('"') | Some('\'') => {
                    let quote = self.next().unwrap();
                    let mut s = String::new();
                    while let Some(c) = self.peek() {
                        if c == quote {
                            self.next();
                            break;
                        }
                        s.push(self.next().unwrap());
                    }
                    tokens.push(Token::String(s));
                }
                Some(c) if c.is_digit(10) => {
                    let mut num = String::new();
                    while let Some(c) = self.peek() {
                        if c.is_digit(10) || c == '.' {
                            num.push(self.next().unwrap());
                        } else {
                            break;
                        }
                    }
                    tokens.push(Token::Number(num.parse().unwrap_or(0.0)));
                }
                Some(c) if c.is_alphabetic() || c == '_' => {
                    let mut word = String::new();
                    while let Some(c) = self.peek() {
                        if c.is_alphanumeric() || c == '_' || c == '.' {
                            word.push(self.next().unwrap());
                        } else {
                            break;
                        }
                    }
                    let upper = word.to_uppercase();
                    match upper.as_str() {
                        "SAY" => tokens.push(Token::Say),
                        "PARSE" => tokens.push(Token::Parse),
                        "ARG" => tokens.push(Token::Arg),
                        "VAR" => tokens.push(Token::Var),
                        "IF" => tokens.push(Token::If),
                        "THEN" => tokens.push(Token::Then),
                        "ELSE" => tokens.push(Token::Else),
                        "DO" => tokens.push(Token::Do),
                        "END" => tokens.push(Token::End),
                        "TO" => tokens.push(Token::To),
                        "BY" => tokens.push(Token::By),
                        "WHILE" => tokens.push(Token::While),
                        "UNTIL" => tokens.push(Token::Until),
                        "LEAVE" => tokens.push(Token::Leave),
                        "ITERATE" => tokens.push(Token::Iterate),
                        "EXIT" => tokens.push(Token::Exit),
                        "RETURN" => tokens.push(Token::Return),
                        "CALL" => tokens.push(Token::Call),
                        "PROCEDURE" => tokens.push(Token::Procedure),
                        "EXPOSE" => tokens.push(Token::Expose),
                        "SELECT" => tokens.push(Token::Select),
                        "WHEN" => tokens.push(Token::When),
                        "OTHERWISE" => tokens.push(Token::Otherwise),
                        "NOP" => tokens.push(Token::NOP),
                        "AND" => tokens.push(Token::And),
                        "OR" => tokens.push(Token::Or),
                        "NOT" => tokens.push(Token::Not),
                        _ => tokens.push(Token::Identifier(word)),
                    }
                }
                Some(_) => {
                    self.next();
                }
            }
        }
        tokens
    }
}

#[derive(Debug, Clone)]
enum Stmt {
    Say(Vec<Expr>),
    ParseArg(Vec<String>),
    Assign(String, Expr),
    If(Expr, Box<Stmt>, Option<Box<Stmt>>),
    DoLoop { var: Option<String>, start: Expr, end: Expr, step: Expr, body: Vec<Stmt> },
    DoWhile(Expr, Vec<Stmt>),
    DoUntil(Expr, Vec<Stmt>),
    Select(Vec<(Expr, Vec<Stmt>)>, Vec<Stmt>),
    Call(String, Vec<Expr>),
    Procedure(Vec<String>),
    Exit(Expr),
    Return(Expr),
    Leave,
    Iterate,
    Nop,
    Block(Vec<Stmt>),
}

#[derive(Debug, Clone)]
enum Expr {
    Var(String),
    Str(String),
    Num(f64),
    BinOp(Box<Expr>, BinOp, Box<Expr>),
    UnOp(UnOp, Box<Expr>),
    Call(String, Vec<Expr>),
}

impl std::fmt::Display for Expr {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Expr::Var(s) => write!(f, "{}", s),
            Expr::Str(s) => write!(f, "\"{}\"", s),
            Expr::Num(n) => write!(f, "{}", n),
            Expr::BinOp(left, op, right) => write!(f, "({} {} {})", left, op, right),
            Expr::UnOp(op, expr) => write!(f, "{}{}", op, expr),
            Expr::Call(name, args) => {
                write!(f, "{}(", name)?;
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 { write!(f, ", ")?; }
                    write!(f, "{}", arg)?;
                }
                write!(f, ")")
            }
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum BinOp {
    Add, Sub, Mul, Div, Mod,
    Eq, Neq, Lt, Gt, Leq, Geq,
    And, Or, Concat,
}

impl std::fmt::Display for BinOp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            BinOp::Add => "+",
            BinOp::Sub => "-",
            BinOp::Mul => "*",
            BinOp::Div => "/",
            BinOp::Mod => "%",
            BinOp::Eq => "=",
            BinOp::Neq => "\\=",
            BinOp::Lt => "<",
            BinOp::Gt => ">",
            BinOp::Leq => "<=",
            BinOp::Geq => ">=",
            BinOp::And => "&",
            BinOp::Or => "|",
            BinOp::Concat => "||",
        };
        write!(f, "{}", s)
    }
}

#[derive(Debug, Clone)]
enum UnOp {
    Not, Neg,
}

impl std::fmt::Display for UnOp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            UnOp::Not => "\\",
            UnOp::Neg => "-",
        };
        write!(f, "{}", s)
    }
}

struct Parser {
    tokens: Vec<Token>,
    pos: usize,
}

impl Parser {
    fn new(tokens: Vec<Token>) -> Self {
        Parser { tokens, pos: 0 }
    }

    fn peek(&self) -> &Token {
        self.tokens.get(self.pos).unwrap_or(&Token::EOF)
    }

    fn next(&mut self) -> Token {
        let t = self.tokens.get(self.pos).cloned().unwrap_or(Token::EOF);
        self.pos += 1;
        t
    }

    fn parse_program(&mut self) -> Vec<Stmt> {
        let mut stmts = Vec::new();
        while !matches!(self.peek(), Token::EOF) {
            if let Some(s) = self.parse_stmt() {
                stmts.push(s);
            }
        }
        stmts
    }

    fn parse_stmt(&mut self) -> Option<Stmt> {
        match self.peek().clone() {
            Token::Say => {
                self.next();
                let mut args = Vec::new();
                loop {
                    match self.peek() {
                        Token::Semi | Token::EOF | Token::End => break,
                        Token::If | Token::Do | Token::Select | Token::Exit | Token::Return |
                        Token::Leave | Token::Iterate | Token::NOP | Token::Else | Token::When |
                        Token::Otherwise | Token::Then => break,
                        _ => {
                            if let Token::Identifier(_) = self.peek() {
                                let pos = self.pos;
                                let next_token = self.tokens.get(pos + 1).cloned();
                                self.pos = pos;
                                if matches!(next_token, Some(Token::Eq)) {
                                    break;
                                }
                            }
                            args.push(self.parse_expr());
                            if matches!(self.peek(), Token::Comma) {
                                self.next();
                            } else if !matches!(self.peek(), Token::Identifier(_) | Token::String(_) | Token::Number(_) | Token::LParen | Token::Minus | Token::Not) {
                                break;
                            }
                        }
                    }
                }
                Some(Stmt::Say(args))
            }
            Token::Parse => {
                self.next();
                match self.peek().clone() {
                    Token::Arg => {
                        self.next();
                        let mut vars = Vec::new();
                        loop {
                            match self.peek() {
                                Token::Semi | Token::EOF | Token::End => break,
                                Token::If | Token::Do | Token::Select | Token::Exit | Token::Return |
                                Token::Leave | Token::Iterate | Token::NOP | Token::Else | Token::When |
                                Token::Otherwise | Token::Then => break,
                                _ => {
                                    if let Token::Identifier(name) = self.next() {
                                        vars.push(name);
                                    }
                                    if matches!(self.peek(), Token::Comma) {
                                        self.next();
                                    } else {
                                        break;
                                    }
                                }
                            }
                        }
                        Some(Stmt::ParseArg(vars))
                    }
                    _ => {
                        // PARSE VALUE expr . VAR
                        self.next(); // skip next token
                        let mut vars = Vec::new();
                        loop {
                            match self.peek() {
                                Token::Semi | Token::EOF | Token::End => break,
                                _ => {
                                    if let Token::Identifier(name) = self.next() {
                                        vars.push(name);
                                    }
                                    if matches!(self.peek(), Token::Comma) {
                                        self.next();
                                    } else {
                                        break;
                                    }
                                }
                            }
                        }
                        Some(Stmt::ParseArg(vars))
                    }
                }
            }
            Token::If => {
                self.next();
                let cond = self.parse_expr();
                self.next(); // THEN
                let then = self.parse_stmt();
                let else_ = if matches!(self.peek(), Token::Else) {
                    self.next();
                    Some(Box::new(self.parse_stmt().unwrap()))
                } else {
                    None
                };
                Some(Stmt::If(cond, Box::new(then.unwrap()), else_))
            }
            Token::Do => {
                self.next();
                if matches!(self.peek(), Token::While) {
                    self.next();
                    let cond = self.parse_expr();
                    let body = self.parse_block();
                    Some(Stmt::DoWhile(cond, body))
                } else if matches!(self.peek(), Token::Until) {
                    self.next();
                    let cond = self.parse_expr();
                    let body = self.parse_block();
                    Some(Stmt::DoUntil(cond, body))
                } else if matches!(self.peek(), Token::Identifier(_)) {
                    let var = match self.next() {
                        Token::Identifier(s) => s,
                        _ => unreachable!(),
                    };
                    self.next(); // =
                    let start = self.parse_expr();
                    self.next(); // TO
                    let end = self.parse_expr();
                    let step = if matches!(self.peek(), Token::By) {
                        self.next();
                        self.parse_expr()
                    } else {
                        Expr::Num(1.0)
                    };
                    let body = self.parse_block();
                    Some(Stmt::DoLoop { var: Some(var), start, end, step, body })
                } else {
                    let body = self.parse_block();
                    Some(Stmt::DoLoop { var: None, start: Expr::Num(0.0), end: Expr::Num(0.0), step: Expr::Num(1.0), body })
                }
            }
            Token::Select => {
                self.next();
                let mut when = Vec::new();
                let mut otherwise = Vec::new();
                loop {
                    match self.peek() {
                        Token::When => {
                            self.next();
                            let cond = self.parse_expr();
                            self.next(); // THEN
                            let body = self.parse_block();
                            when.push((cond, body));
                        }
                        Token::Otherwise => {
                            self.next();
                            otherwise = self.parse_block();
                        }
                        Token::End => { self.next(); break; }
                        _ => { self.next(); }
                    }
                }
                Some(Stmt::Select(when, otherwise))
            }
            Token::Exit => {
                self.next();
                let expr = self.parse_expr();
                Some(Stmt::Exit(expr))
            }
            Token::Return => {
                self.next();
                let expr = self.parse_expr();
                Some(Stmt::Return(expr))
            }
            Token::Leave => { self.next(); Some(Stmt::Leave) }
            Token::Iterate => { self.next(); Some(Stmt::Iterate) }
            Token::NOP => { self.next(); Some(Stmt::Nop) }
            Token::Procedure => {
                self.next();
                let mut expose = Vec::new();
                if matches!(self.peek(), Token::Expose) {
                    self.next();
                    loop {
                        match self.peek() {
                            Token::Semi | Token::EOF | Token::End => break,
                            _ => {
                                if let Token::Identifier(name) = self.next() {
                                    expose.push(name);
                                }
                                if matches!(self.peek(), Token::Comma) {
                                    self.next();
                                } else {
                                    break;
                                }
                            }
                        }
                    }
                }
                Some(Stmt::Procedure(expose))
            }
            Token::Identifier(name) => {
                self.next();
                // Check for stem variable (e.g., stem.0.field)
                let mut full_name = name;
                while matches!(self.peek(), Token::Dot) {
                    self.next(); // consume dot
                    match self.peek().clone() {
                        Token::Number(n) => {
                            self.next();
                            full_name = format!("{}.{}", full_name, n as i64);
                        }
                        Token::Identifier(s) => {
                            self.next();
                            // Dynamic stem index - evaluate as variable
                            full_name = format!("{}.{}", full_name, s);
                        }
                        _ => break,
                    }
                }
                if matches!(self.peek(), Token::LParen) {
                    self.next();
                    let mut args = Vec::new();
                    if !matches!(self.peek(), Token::RParen) {
                        args.push(self.parse_expr());
                        while matches!(self.peek(), Token::Comma) {
                            self.next();
                            args.push(self.parse_expr());
                        }
                    }
                    self.next(); // )
                    Some(Stmt::Call(full_name, args))
                } else if matches!(self.peek(), Token::Eq) {
                    self.next(); // =
                    let expr = self.parse_expr();
                    Some(Stmt::Assign(full_name, expr))
                } else {
                    // Just a variable reference - shouldn't happen as statement
                    None
                }
            }
            _ => {
                self.next();
                None
            }
        }
    }

    fn parse_block(&mut self) -> Vec<Stmt> {
        let mut stmts = Vec::new();
        loop {
            match self.peek() {
                Token::End | Token::EOF => { self.next(); break; }
                Token::Otherwise => break,
                _ => {
                    if let Some(s) = self.parse_stmt() {
                        stmts.push(s);
                    }
                }
            }
        }
        stmts
    }

    fn parse_expr(&mut self) -> Expr {
        self.parse_or()
    }

    fn parse_or(&mut self) -> Expr {
        let mut left = self.parse_and();
        while matches!(self.peek(), Token::Or) {
            self.next();
            let right = self.parse_and();
            left = Expr::BinOp(Box::new(left), BinOp::Or, Box::new(right));
        }
        left
    }

    fn parse_and(&mut self) -> Expr {
        let mut left = self.parse_not();
        while matches!(self.peek(), Token::And) {
            self.next();
            let right = self.parse_not();
            left = Expr::BinOp(Box::new(left), BinOp::And, Box::new(right));
        }
        left
    }

    fn parse_not(&mut self) -> Expr {
        if matches!(self.peek(), Token::Not) {
            self.next();
            let expr = self.parse_not();
            Expr::UnOp(UnOp::Not, Box::new(expr))
        } else {
            self.parse_concat()
        }
    }

    fn parse_concat(&mut self) -> Expr {
        let mut left = self.parse_comparison();
        while matches!(self.peek(), Token::Concat) {
            self.next();
            let right = self.parse_comparison();
            left = Expr::BinOp(Box::new(left), BinOp::Concat, Box::new(right));
        }
        left
    }

    fn parse_comparison(&mut self) -> Expr {
        let mut left = self.parse_addition();
        loop {
            match self.peek() {
                Token::Eq => { self.next(); let r = self.parse_addition(); left = Expr::BinOp(Box::new(left), BinOp::Eq, Box::new(r)); }
                Token::Neq => { self.next(); let r = self.parse_addition(); left = Expr::BinOp(Box::new(left), BinOp::Neq, Box::new(r)); }
                Token::Lt => { self.next(); let r = self.parse_addition(); left = Expr::BinOp(Box::new(left), BinOp::Lt, Box::new(r)); }
                Token::Gt => { self.next(); let r = self.parse_addition(); left = Expr::BinOp(Box::new(left), BinOp::Gt, Box::new(r)); }
                Token::Leq => { self.next(); let r = self.parse_addition(); left = Expr::BinOp(Box::new(left), BinOp::Leq, Box::new(r)); }
                Token::Geq => { self.next(); let r = self.parse_addition(); left = Expr::BinOp(Box::new(left), BinOp::Geq, Box::new(r)); }
                _ => break,
            }
        }
        left
    }

    fn parse_addition(&mut self) -> Expr {
        let mut left = self.parse_multiplication();
        loop {
            match self.peek() {
                Token::Plus => { self.next(); let r = self.parse_multiplication(); left = Expr::BinOp(Box::new(left), BinOp::Add, Box::new(r)); }
                Token::Minus => { self.next(); let r = self.parse_multiplication(); left = Expr::BinOp(Box::new(left), BinOp::Sub, Box::new(r)); }
                _ => break,
            }
        }
        left
    }

    fn parse_multiplication(&mut self) -> Expr {
        let mut left = self.parse_unary();
        loop {
            match self.peek() {
                Token::Star => { self.next(); let r = self.parse_unary(); left = Expr::BinOp(Box::new(left), BinOp::Mul, Box::new(r)); }
                Token::Slash => { self.next(); let r = self.parse_unary(); left = Expr::BinOp(Box::new(left), BinOp::Div, Box::new(r)); }
                Token::Percent => { self.next(); let r = self.parse_unary(); left = Expr::BinOp(Box::new(left), BinOp::Mod, Box::new(r)); }
                _ => break,
            }
        }
        left
    }

    fn parse_unary(&mut self) -> Expr {
        match self.peek() {
            Token::Minus => {
                self.next();
                let expr = self.parse_atom();
                Expr::UnOp(UnOp::Neg, Box::new(expr))
            }
            _ => self.parse_atom(),
        }
    }

    fn parse_atom(&mut self) -> Expr {
        match self.peek().clone() {
            Token::String(s) => { self.next(); Expr::Str(s) }
            Token::Number(n) => { self.next(); Expr::Num(n) }
            Token::LParen => {
                self.next();
                let expr = self.parse_expr();
                self.next(); // )
                expr
            }
            Token::Identifier(name) => {
                self.next();
                // Handle stem variables (e.g., record.j.name, receipt.(i-1).tx_id)
                let mut full_name = name;
                while matches!(self.peek(), Token::Dot) {
                    self.next(); // consume dot
                    match self.peek().clone() {
                        Token::Number(n) => {
                            self.next();
                            full_name = format!("{}.{}", full_name, n as i64);
                        }
                        Token::Identifier(s) => {
                            self.next();
                            full_name = format!("{}.{}", full_name, s);
                        }
                        Token::LParen => {
                            self.next();
                            let index_expr = self.parse_expr();
                            if matches!(self.peek(), Token::RParen) {
                                self.next(); // consume )
                            }
                            // Use a special marker for computed index
                            full_name = format!("{}.({})", full_name, index_expr);
                        }
                        _ => break,
                    }
                }
                if matches!(self.peek(), Token::LParen) {
                    self.next();
                    let mut args = Vec::new();
                    if !matches!(self.peek(), Token::RParen) {
                        args.push(self.parse_expr());
                        while matches!(self.peek(), Token::Comma) {
                            self.next();
                            args.push(self.parse_expr());
                        }
                    }
                    self.next(); // )
                    Expr::Call(full_name, args)
                } else {
                    Expr::Var(full_name)
                }
            }
            _ => Expr::Num(0.0),
        }
    }
}

struct Scope {
    vars: HashMap<String, Value>,
}

struct Interpreter {
    scopes: Vec<Scope>,
    call_stack: Vec<(String, Vec<Stmt>, usize)>, // (name, body, return_pos)
    args_stack: Vec<Vec<Value>>,
    output: Vec<String>,
}

impl Interpreter {
    fn new() -> Self {
        Interpreter {
            scopes: vec![Scope { vars: HashMap::new() }],
            call_stack: Vec::new(),
            args_stack: Vec::new(),
            output: Vec::new(),
        }
    }

    fn current_scope(&mut self) -> &mut Scope {
        self.scopes.last_mut().unwrap()
    }

    fn get_var(&self, name: &str) -> Value {
        // Search from innermost to outermost scope
        for scope in self.scopes.iter().rev() {
            if let Some(val) = scope.vars.get(name) {
                return val.clone();
            }
        }
        Value::Str(String::new())
    }

    fn set_var(&mut self, name: &str, val: Value) {
        self.scopes.last_mut().unwrap().vars.insert(name.to_string(), val);
    }

    fn push_scope(&mut self) {
        self.scopes.push(Scope { vars: HashMap::new() });
    }

    fn pop_scope(&mut self) {
        if self.scopes.len() > 1 {
            self.scopes.pop();
        }
    }

    fn run(&mut self, source: &str) -> Result<(), String> {
        let mut lexer = Lexer::new(source);
        let tokens = lexer.tokenize();
        let mut parser = Parser::new(tokens);
        let stmts = parser.parse_program();
        self.exec_block(&stmts)?;
        Ok(())
    }

    fn exec_block(&mut self, stmts: &[Stmt]) -> Result<(), String> {
        for stmt in stmts {
            self.exec_stmt(stmt)?;
        }
        Ok(())
    }

    fn exec_stmt(&mut self, stmt: &Stmt) -> Result<(), String> {
        match stmt {
            Stmt::Say(exprs) => {
                let parts: Vec<String> = exprs.iter().map(|e| self.eval_expr(e).to_str()).collect();
                let line = parts.join(" ");
                println!("{}", line);
                self.output.push(line);
            }
            Stmt::ParseArg(var_names) => {
                // Get arguments from call stack
                let args = self.args_stack.last().cloned().unwrap_or_default();
                for (i, name) in var_names.iter().enumerate() {
                    let val = if i < args.len() {
                        args[i].clone()
                    } else {
                        Value::Str(String::new())
                    };
                    self.set_var(name, val);
                }
            }
            Stmt::Assign(name, expr) => {
                let val = self.eval_expr(expr);
                // Handle dynamic stem indices in assignment
                // Only first segment after stem can be dynamic variable
                let actual_name = if name.contains('.') {
                    let dot_pos = name.find('.').unwrap();
                    let base = &name[..dot_pos];
                    let rest = &name[dot_pos + 1..];
                    if let Some(next_dot) = rest.find('.') {
                        let index_part = &rest[..next_dot];
                        let suffix = &rest[next_dot + 1..];
                        if !index_part.chars().next().map_or(false, |c| c.is_digit(10)) {
                            let index_val = self.get_var(index_part);
                            format!("{}.{}.{}", base, index_val.to_str(), suffix)
                        } else {
                            name.clone()
                        }
                    } else if !rest.chars().next().map_or(false, |c| c.is_digit(10)) {
                        let index_val = self.get_var(rest);
                        format!("{}.{}", base, index_val.to_str())
                    } else {
                        name.clone()
                    }
                } else {
                    name.clone()
                };
                self.set_var(&actual_name, val);
            }
            Stmt::If(cond, then, else_) => {
                if self.eval_expr(cond).is_true() {
                    self.exec_stmt(then)?;
                } else if let Some(e) = else_ {
                    self.exec_stmt(e)?;
                }
            }
            Stmt::DoLoop { var, start, end, step, body } => {
                let s = self.eval_expr(start).to_num();
                let e = self.eval_expr(end).to_num();
                let st = self.eval_expr(step).to_num();
                let mut i = s;
                loop {
                    if st > 0.0 && i > e { break; }
                    if st < 0.0 && i < e { break; }
                    if let Some(v) = var {
                        self.set_var(v, Value::Num(i));
                    }
                    match self.exec_block(body) {
                        Err(ref err) if err == "LEAVE" => break,
                        Err(ref err) if err == "ITERATE" => {}
                        Err(e) => return Err(e),
                        Ok(()) => {}
                    }
                    i += st;
                }
            }
            Stmt::DoWhile(cond, body) => {
                while self.eval_expr(cond).is_true() {
                    match self.exec_block(body) {
                        Err(ref err) if err == "LEAVE" => break,
                        Err(ref err) if err == "ITERATE" => {}
                        Err(e) => return Err(e),
                        Ok(()) => {}
                    }
                }
            }
            Stmt::DoUntil(cond, body) => {
                loop {
                    match self.exec_block(body) {
                        Err(ref err) if err == "LEAVE" => break,
                        Err(ref err) if err == "ITERATE" => {}
                        Err(e) => return Err(e),
                        Ok(()) => {}
                    }
                    if self.eval_expr(cond).is_true() { break; }
                }
            }
            Stmt::Select(when, otherwise) => {
                let mut matched = false;
                for (cond, body) in when {
                    if self.eval_expr(cond).is_true() {
                        self.exec_block(body)?;
                        matched = true;
                        break;
                    }
                }
                if !matched && !otherwise.is_empty() {
                    self.exec_block(otherwise)?;
                }
            }
            Stmt::Call(name, args) => {
                let arg_vals: Vec<Value> = args.iter().map(|a| self.eval_expr(a)).collect();
                self.call_fn(name, &arg_vals)?;
            }
            Stmt::Procedure(_expose) => {
                // PROCEDURE starts a new scope - handled by CALL
                self.push_scope();
            }
            Stmt::Exit(expr) => {
                let code = self.eval_expr(expr).to_num() as i32;
                std::process::exit(code);
            }
            Stmt::Return(expr) => {
                let val = self.eval_expr(expr);
                return Err(format!("RETURN({})", val.to_str()));
            }
            Stmt::Leave => return Err("LEAVE".to_string()),
            Stmt::Iterate => return Err("ITERATE".to_string()),
            Stmt::Nop => {}
            Stmt::Block(stmts) => self.exec_block(stmts)?,
        }
        Ok(())
    }

    fn call_fn(&mut self, name: &str, args: &[Value]) -> Result<Value, String> {
        match name.to_uppercase().as_str() {
            "LENGTH" => Ok(Value::Num(args[0].to_str().len() as f64)),
            "SUBSTR" => {
                let s = args[0].to_str();
                let start = args[1].to_num() as usize;
                let len = args.get(2).map(|a| a.to_num() as usize).unwrap_or(s.len());
                Ok(Value::Str(s.chars().skip(start - 1).take(len).collect()))
            }
            "POS" => {
                let needle = args[0].to_str();
                let haystack = args[1].to_str();
                let start = args.get(2).map(|a| a.to_num() as usize).unwrap_or(1);
                match haystack[start - 1..].find(&needle) {
                    Some(i) => Ok(Value::Num((start + i) as f64)),
                    None => Ok(Value::Num(0.0)),
                }
            }
            "LEFT" => {
                let s = args[0].to_str();
                let n = args[1].to_num() as usize;
                Ok(Value::Str(s.chars().take(n).collect()))
            }
            "RIGHT" => {
                let s = args[0].to_str();
                let n = args[1].to_num() as usize;
                let len = s.chars().count();
                Ok(Value::Str(s.chars().skip(len.saturating_sub(n)).collect()))
            }
            "UPPER" | "UPPERCASE" => Ok(Value::Str(args[0].to_str().to_uppercase())),
            "LOWER" | "LOWERCASE" => Ok(Value::Str(args[0].to_str().to_lowercase())),
            "STRIP" => Ok(Value::Str(args[0].to_str().trim().to_string())),
            "DATATYPE" => {
                let s = args[0].to_str();
                if s.parse::<f64>().is_ok() { Ok(Value::Str("NUM".to_string())) }
                else { Ok(Value::Str("CHAR".to_string())) }
            }
            "TIME" => {
                let now = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_secs();
                Ok(Value::Num(now as f64))
            }
            "DATE" => {
                let now = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_secs();
                Ok(Value::Num(now as f64))
            }
            "SHA256" => {
                use std::collections::hash_map::DefaultHasher;
                use std::hash::{Hash, Hasher};
                let s = args[0].to_str();
                let mut hasher = DefaultHasher::new();
                s.hash(&mut hasher);
                let hash = hasher.finish();
                Ok(Value::Str(format!("{:016x}", hash)))
            }
            "WORD" => {
                let s = args[0].to_str();
                let n = args[1].to_num() as usize;
                let words: Vec<&str> = s.split_whitespace().collect();
                if n > 0 && n <= words.len() {
                    Ok(Value::Str(words[n - 1].to_string()))
                } else {
                    Ok(Value::Str(String::new()))
                }
            }
            "WORDS" => {
                let s = args[0].to_str();
                Ok(Value::Num(s.split_whitespace().count() as f64))
            }
            "TRANSLATE" => {
                let s = args[0].to_str();
                Ok(Value::Str(s.to_uppercase()))
            }
            "VALUE" => {
                let name = args[0].to_str();
                Ok(self.get_var(&name))
            }
            _ => {
                // Check if it's a user-defined function (procedure call)
                self.call_proc(name, args)
            }
        }
    }

    fn call_proc(&mut self, name: &str, args: &[Value]) -> Result<Value, String> {
        // Save current scope state
        let saved_scope_len = self.scopes.len();
        
        // Push new scope for procedure
        self.push_scope();
        
        // Push arguments
        self.args_stack.push(args.to_vec());
        
        // Execute procedure body
        // For now, we'll look for the procedure in the global scope
        // This is a simplified version - in a full implementation,
        // we'd need to parse and store procedure definitions
        
        // Pop scope and args
        self.args_stack.pop();
        self.pop_scope();
        
        Ok(Value::Str(String::new()))
    }

    fn eval_expr(&mut self, expr: &Expr) -> Value {
        match expr {
            Expr::Var(name) => {
                // Handle dynamic stem variables (e.g., z.i, record.1.name, receipt.(i-1).tx_id)
                if name.contains('.') {
                    // Check for computed index format: stem.(expr).suffix
                    if let Some(paren_start) = name.find(".(") {
                        if let Some(paren_end) = name[paren_start+2..].find(')') {
                            let base = &name[..paren_start];
                            let expr_str = &name[paren_start+2..paren_start+2+paren_end];
                            let suffix_start = paren_start + 2 + paren_end + 1;
                            let suffix = if suffix_start < name.len() && &name[suffix_start..suffix_start+1] == "." {
                                &name[suffix_start+1..]
                            } else {
                                ""
                            };
                            
                            // Parse and evaluate the index expression
                            let mut lexer = Lexer::new(expr_str);
                            let tokens = lexer.tokenize();
                            let mut parser = Parser::new(tokens);
                            let index_expr = parser.parse_expr();
                            let index_val = self.eval_expr(&index_expr);
                            
                            let full_name = if suffix.is_empty() {
                                format!("{}.{}", base, index_val.to_str())
                            } else {
                                format!("{}.{}.{}", base, index_val.to_str(), suffix)
                            };
                            return self.get_var(&full_name);
                        }
                    }
                    
                    // Standard dynamic index: stem.index.suffix where index is a variable
                    let dot_pos = name.find('.').unwrap();
                    let base = &name[..dot_pos];
                    let rest = &name[dot_pos + 1..];
                    if let Some(next_dot) = rest.find('.') {
                        let index_part = &rest[..next_dot];
                        let suffix = &rest[next_dot + 1..];
                        if !index_part.chars().next().map_or(false, |c| c.is_digit(10)) {
                            let index_val = self.get_var(index_part);
                            let full_name = format!("{}.{}.{}", base, index_val.to_str(), suffix);
                            return self.get_var(&full_name);
                        }
                    } else if !rest.chars().next().map_or(false, |c| c.is_digit(10)) {
                        let index_val = self.get_var(rest);
                        let full_name = format!("{}.{}", base, index_val.to_str());
                        return self.get_var(&full_name);
                    }
                }
                self.get_var(name)
            }
            Expr::Str(s) => Value::Str(s.clone()),
            Expr::Num(n) => Value::Num(*n),
            Expr::BinOp(left, op, right) => {
                let l = self.eval_expr(left);
                let r = self.eval_expr(right);
                match op {
                    BinOp::Add => Value::Num(l.to_num() + r.to_num()),
                    BinOp::Sub => Value::Num(l.to_num() - r.to_num()),
                    BinOp::Mul => Value::Num(l.to_num() * r.to_num()),
                    BinOp::Div => Value::Num(l.to_num() / r.to_num()),
                    BinOp::Mod => Value::Num(l.to_num() % r.to_num()),
                    BinOp::Eq => Value::Bool(l.to_str() == r.to_str()),
                    BinOp::Neq => Value::Bool(l.to_str() != r.to_str()),
                    BinOp::Lt => Value::Bool(l.to_num() < r.to_num()),
                    BinOp::Gt => Value::Bool(l.to_num() > r.to_num()),
                    BinOp::Leq => Value::Bool(l.to_num() <= r.to_num()),
                    BinOp::Geq => Value::Bool(l.to_num() >= r.to_num()),
                    BinOp::And => Value::Bool(l.is_true() && r.is_true()),
                    BinOp::Or => Value::Bool(l.is_true() || r.is_true()),
                    BinOp::Concat => Value::Str(format!("{}{}", l.to_str(), r.to_str())),
                }
            }
            Expr::UnOp(op, expr) => {
                let val = self.eval_expr(expr);
                match op {
                    UnOp::Not => Value::Bool(!val.is_true()),
                    UnOp::Neg => Value::Num(-val.to_num()),
                }
            }
            Expr::Call(name, args) => {
                let arg_vals: Vec<Value> = args.iter().map(|a| self.eval_expr(a)).collect();
                self.call_fn(name, &arg_vals).unwrap_or(Value::Str(String::new()))
            }
        }
    }
}
