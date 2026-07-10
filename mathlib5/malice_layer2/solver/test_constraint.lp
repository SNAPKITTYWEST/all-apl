% Test: 2*x + 3 <= 10 is SAT (x=0 works)
% Goal: find x where 2*x + 3 > 10 (refutation)
(assert (<= (+ (* 2 x) 3) 10))
(goal (<= x 100))
