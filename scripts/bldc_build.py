from tests import BLDCsimpleTest

bldc_opneloop = BLDCsimpleTest('tb_bldc_commutator')
# Ejecutar comando iverilog
bldc_opneloop.build()