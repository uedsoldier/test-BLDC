from tests import BLDCsimpleTest

bldc_openloop = BLDCsimpleTest('tb_bldc_commutator')
# Ejecutar comando iverilog
bldc_openloop.build()