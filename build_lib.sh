#!/bin/bash
# Verilog tasarimlarindan C++ kutuphanesi (libgeomchip.so) uretir ve test eder. Verilator gerekir.
set -e
cd "$(dirname "$0")"
VR=$(verilator --getenv VERILATOR_ROOT)
OUT=build; rm -rf $OUT; mkdir -p $OUT
TOPS="fp64_add fp64_mul fp64_div vec3_dot vec3_cross mat4_mul aabb_overlap aabb_multi nurbs3_eval"
INC="-I$VR/include -I$VR/include/vltstd"
for t in $TOPS; do
  echo "== verilator $t"
  verilator --cc -Wno-fatal -Wno-lint -Wno-style -O3 --prefix V$t --Mdir $OUT/$t --top-module $t ../rtl/*.v > $OUT/$t.log 2>&1 \
    || { echo "FAIL verilator $t"; tail -40 $OUT/$t.log; exit 1; }
  ( cd $OUT/$t && g++ -std=c++17 -O1 -fPIC -faligned-new -pthread -c *.cpp -I. $INC ) \
    || { echo "FAIL derleme $t"; exit 1; }
done
EXTRA=""; [ -f $VR/include/verilated_threads.cpp ] && EXTRA="$VR/include/verilated_threads.cpp"
INCALL=""; for t in $TOPS; do INCALL="$INCALL -I$OUT/$t"; done
echo "== kutuphane"
g++ -std=c++17 -O2 -fPIC -shared -pthread -faligned-new chip_api.cpp $OUT/*/*.o $VR/include/verilated.cpp $EXTRA $INCALL $INC -o libgeomchip.so
g++ -std=c++17 -O2 -ffp-contract=off chip_selftest.cpp -L. -lgeomchip -Wl,-rpath,'$ORIGIN' -o selftest
echo "== kendi kendini test"
./selftest
