/* simple_test.rexx — Simple REXX test */
SAY "Hello from REXX interpreter!"
SAY "Testing basic features..."

/* Variables */
x = 10
y = 20
z = x + y
SAY "x + y =" z

/* String operations */
name = "MATHLIB5"
SAY "Name:" name
SAY "Length:" LENGTH(name)

/* Loop */
DO i = 1 TO 5
    SAY "Iteration" i
END

/* Condition */
IF z > 25 THEN DO
    SAY "z is greater than 25"
END
ELSE DO
    SAY "z is not greater than 25"
END

SAY "Test complete!"
EXIT 0
