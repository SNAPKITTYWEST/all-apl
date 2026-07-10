% UNSAT: x + y <= 5 AND x >= 3 AND y >= 4
% 3+4=7 > 5, so UNSAT
(assert (<= (+ x y) 5))
(assert (>= x 3))
(assert (>= y 4))
