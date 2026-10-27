#!/bin/bash
# Evre 3 testleri. sim/ klasorunden: bash run_nurbs.sh
cd "$(dirname "$0")"
python3 gen_nurbs.py || exit 1
status=0
for t in div nurbs; do
    iverilog -g2012 -s tb_$t -o tb_$t.vvp ../rtl/*.v ../tb/tb_$t.v || { echo "FAIL derleme tb_$t"; status=1; continue; }
    vvp tb_$t.vvp | tee tb_$t.log
    grep -q "^PASS" tb_$t.log || status=1
done
[ $status -eq 0 ] && echo "EVRE 3 HEPSI GECTI" || echo "FAIL: bazi Evre 3 testleri basarisiz"
exit $status
