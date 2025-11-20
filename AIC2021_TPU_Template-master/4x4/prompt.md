python3 matmul.py inputs2
iverilog -g2012 -o simv -I 4x4 -I build -Dtest1 -s top_tb 4x4/top_tb.v
vvp simv
