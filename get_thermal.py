import sys

def get_temp(z):
    try:
        with open(f"/sys/class/thermal/{z}/temp", "r") as f:
            v = float(f.read().strip())
            return v / 1000.0 if v > 1000 else v
    except Exception:
        return 0.0

print(f"  • CPU Prime Core 0 (cpu-1-0-1) : {get_temp('thermal_zone26'):.1f} °C", flush=True)
print(f"  • CPU Prime Core 1 (cpu-1-1-1) : {get_temp('thermal_zone28'):.1f} °C", flush=True)
print(f"  • CPU Perf Cores (cpuss-1-1)   : {get_temp('thermal_zone30'):.1f} °C", flush=True)
print(f"  • GPU Adreno 830 (gpuss-4)     : {get_temp('thermal_zone36'):.1f} °C", flush=True)
print(f"  • Bateria (battery)             : {get_temp('thermal_zone80'):.1f} °C", flush=True)
print(f"  • Chassi (skin-msm-therm)       : {get_temp('thermal_zone57'):.1f} °C", flush=True)
