from tests import PWMTest

pwm = PWMTest('tb_pwm_generator_3phase')   

# Ejectuar comando iverilog
pwm.build()
