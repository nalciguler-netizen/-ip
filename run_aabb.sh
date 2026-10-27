#!/bin/bash
# Evre 2 testleri. sim/ klasorunden: bash run_aabb.sh
cd "$(dirname "$0")"
python3 gen_aabb.py || exit 1
status=0
for t in aabb aabb8; do
    iverilog -g2012 -s tb_$t -o tb_$t.vvp ../rtl/*.v ../tb/tb_$t.v || { echo "FAIL derleme tb_$t"; status=1; continue; }
    vvp tb_$t.vvp | tee tb_$t.log
    grep -q "^PASS" tb_$t.log || status=1
done
[ $status -eq 0 ] && echo "EVRE 2 HEPSI GECTI" || echo "FAIL: bazi Evre 2 testleri basarisiz"
exit $status
