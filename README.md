Two incoherent Caches interacting with single memory through memory_access_arbiter.
Read/Writes from Host(CPU) to caches are modeled/initiated through cache_bfm.
Upon cache_miss, the cache initiates memory read/write.
memory_access_arbiter controls which cache gets to access memory at a time.
Cache reads address 0x53 from memory upon cache_miss. After that it writes to that address but that cache entry becomes dirty/incoherent with memory.
Another cache reads old value from memory.
This demonstrates why cache coherency is needed. 

COMPILE:
vcs -lca -timescale=1ns/100ps -sverilog +verilog2001ext+.v -ntb_opts uvm-1.2 +define+WAVES_FSDB -kdb -debug_access+all -l cache_coherence_compile.log -f cache_coherence_tb_files.f -top cache_coherence_top
SIMULATE:
./simv +vcs+lic+wait -l cache_coherence_sim.log +UVM_MAX_QUIT_COUNT=10000 +UVM_LOG_RECORD +UVM_TR_RECORD +ntb_random_seed=8976 +UVM_VERBOSITY=UVM_MEDIUM
