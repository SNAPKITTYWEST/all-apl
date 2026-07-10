% Test: x + y <= 5 AND x >= 3 AND y >= 4
% This is UNSAT (3+4=7 > 5)
(assert (<= (+ x y) 5))
(assert (>= x 3))
(assert (>= y 4))
(goal (<= x 100))
