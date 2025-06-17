# TestVerilog

Proyecto de ejemplo para pruebas y simulación de módulos Verilog.

## Estructura del proyecto

- **src/**: Módulos Verilog fuente (por ejemplo, [`hello.v`](src/hello.v)).
- **testbenches/**: Testbenches para simular los módulos (por ejemplo, [`tb_hello.v`](testbenches/tb_hello.v)).
- **sim/**: Archivos compilados de simulación (`.vvp`).
- **sim_output/**: Resultados de simulación, como archivos VCD para visualización de ondas.

## Uso

### 1. Compilar el testbench

Puedes compilar un testbench usando el siguiente comando (por ejemplo, para `tb_hello`):

```sh
iverilog -o sim/tb_hello.vvp -I src testbenches/tb_hello.v
```

### 2. Ejecutar la simulación

```sh
vvp sim/tb_hello.vvp
```

### 3. Visualizar las señales

Abre el archivo VCD generado con GTKWave:

```sh
gtkwave sim_output/tb_hello.vcd
```

## Automatización con VS Code

Este proyecto incluye tareas preconfiguradas en `.vscode/tasks.json` para compilar, simular y graficar desde Visual Studio Code.

## Requisitos

- [Icarus Verilog](https://iverilog.fandom.com/wiki/Installation)
- [GTKWave](http://gtkwave.sourceforge.net/)
- Visual Studio Code (opcional, para tareas automatizadas)

## Licencia

MIT