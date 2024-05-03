# Incoherent_Cache
 Two incoherent Caches interacting with single memory through memory_access_arbiter. Cache reads address 0x53 from memory upon cache_miss. After that it writes to that address but that cache entry becomes dirty/incoherent with memory. Another cache reads old value from memory. This demonstrates why cache coherency is needed. 
