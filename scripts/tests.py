import subprocess

class BaseTest:
    def __init__(self, tb_name=None):
        self.clk_freq_mhz = int(input('Enter main clock frequency [MHz]: '))
        self.clk_freq_hz = self.clk_freq_mhz * 1_000_000
        self.clk_period_ns = 1_000_000_000 // self.clk_freq_hz
        print(f'Main clock period: {self.clk_period_ns} [ns]')

        self.tb_name = tb_name
        # 📄 Archivos
        self.src_dir = 'src'
        self.tb_file = f'testbenches/{tb_name}.v'
        self.output_file = f'sim/{tb_name}.vvp'

    def verilog_cmd(self):
        # 🚀 Ejecutar
        try:
            result = subprocess.run(self.iverilog_cmd, check=True, capture_output=True, text=True)
            print(f'✅ Compilation successful. Output: {self.output_file}')
        except subprocess.CalledProcessError as e:
            print('❌ Compilation failed.')
            print('🔧 STDOUT:')
            print(e.stdout)
            print('🔧 STDERR:')
            print(e.stderr)
    
    def build(self):
        print('🔧 Compiling with:')
        print(' '.join(self.iverilog_cmd))
        self.verilog_cmd()

    
class PWMTest(BaseTest):
    def __init__(self,tb_name):
        super().__init__(tb_name)

        self.pwm_freq_hz = int(input('Enter PWM frequency [Hz]: '))
        self.pwm_period = self.clk_freq_hz // self.pwm_freq_hz
        print('PWM parameters:')
        print('\tFrequency: {self.pwm_freq_hz} [Hz]')
        print(f'\tPeriod: {self.pwm_period} [cycles] ({self.pwm_period*self.clk_period_ns} [ns])')

        self.duty_a = int(input('Enter duty cycle A (0-PWM period): '))
        self.duty_b = int(input('Enter duty cycle B (0-PWM period): '))
        self.duty_c = int(input('Enter duty cycle C (0-PWM period): '))

        self.iverilog_cmd = [
            'iverilog',
            '-o', self.output_file,
            '-I', self.src_dir,
            f'-DMAIN_CLOCK_PERIOD_NS={self.clk_period_ns}',
            f'-DPWM_PERIOD={self.pwm_period}',
            f'-DDUTY_A={self.duty_a}',
            f'-DDUTY_B={self.duty_b}',
            f'-DDUTY_C={self.duty_c}',
            self.tb_file,
        ]

class BLDCsimpleTest(BaseTest):
    def __init__(self,tb_name):
        super().__init__(tb_name)

        self.step_duration_ns = int(input('Enter open-loop step duration [ns]: '))
        self.step_duration_cycles = self.step_duration_ns // self.clk_period_ns
        print(f'Open-loop step duration: {self.step_duration_ns} [ns] ({self.step_duration_cycles} clk cycles)')
        self.iverilog_cmd = [
            'iverilog',
            '-o', self.output_file,
            '-I', self.src_dir, 
            f'-DMAIN_CLOCK_PERIOD_NS={self.clk_period_ns}',
            f'-DSTEP_DURATION_CYCLES={self.step_duration_cycles}',
            self.tb_file,
        ]
    
class HallTest(BaseTest):
    def __init__(self, tb_name):
        super().__init__(tb_name)

        self.hall_simulated_period_ns = int(input('Enter simulated Hall sensor period in [ns]: '))
        self.hall_simulated_period_clk = self.hall_simulated_period_ns // self.clk_period_ns
        print(f'Simulated Hall sensor period (cycles): {self.hall_simulated_period_clk}')

        self.hall_simulated_strobe_duration_ns = int(input('Enter simulated Hall sensor strobe duration in [ns]: '))
        self.hall_simulated_strobe_duration_clk = self.hall_simulated_strobe_duration_ns // self.clk_period_ns
        print(f'Simulated Hall sensor strobe duration (cycles): {self.hall_simulated_strobe_duration_clk}')

        self.iverilog_cmd = [
            'iverilog',
            '-o', self.output_file,
            '-I', self.src_dir,
            f'-DMAIN_CLOCK_PERIOD_NS={self.clk_period_ns}',
            f'-DHALL_SENSOR_PERIOD_CLK={self.hall_simulated_period_clk}',
            f'-DHALL_SENSOR_STROBE_DURATION_CLK={self.hall_simulated_strobe_duration_clk}',
            self.tb_file,
        ]

class BLDCPWMTest(BaseTest):
    def __init__(self, tb_name):
        super().__init__(tb_name)
        self.pwm_freq_hz = int(input('Enter PWM frequency [Hz]: '))
        self.pwm_period = self.clk_freq_hz // self.pwm_freq_hz
        print('PWM parameters:')
        print('\tFrequency: {self.pwm_freq_hz} [Hz]')
        print(f'\tPeriod: {self.pwm_period} [cycles] ({self.pwm_period*self.clk_period_ns} [ns])')

        # All duty cycles must be the same for BLDC PWM
        self.duty = int(input('Enter duty cycle (0-PWM period): '))


        self.step_duration_ns = int(input('Enter open-loop step duration [ns]: '))
        self.step_duration_cycles = self.step_duration_ns // self.clk_period_ns
        print(f'Open-loop step duration: {self.step_duration_ns} [ns] ({self.step_duration_cycles} clk cycles)')


        self.iverilog_cmd = [
            'iverilog',
            '-o', self.output_file,
            '-I', self.src_dir,
            f'-DMAIN_CLOCK_PERIOD_NS={self.clk_period_ns}',
            f'-DSTEP_DURATION_CYCLES={self.step_duration_cycles}',
            f'-DPWM_PERIOD={self.pwm_period}',
            f'-DDUTY={self.duty}',
            self.tb_file,
        ]