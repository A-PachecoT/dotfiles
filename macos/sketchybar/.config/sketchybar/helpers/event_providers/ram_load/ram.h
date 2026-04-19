#include <mach/mach.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/sysctl.h>

struct ram {
  host_t host;
  uint64_t total_bytes;

  int used_percent;
  int swap_used_mb;
  int swap_total_mb;
  int pressure;
};

static inline void ram_init(struct ram* ram) {
  ram->host = mach_host_self();

  int mib[2] = { CTL_HW, HW_MEMSIZE };
  size_t len = sizeof(ram->total_bytes);
  sysctl(mib, 2, &ram->total_bytes, &len, NULL, 0);
}

static inline void ram_update(struct ram* ram) {
  mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
  vm_statistics64_data_t vm_stat;

  kern_return_t error = host_statistics64(ram->host,
                                          HOST_VM_INFO64,
                                          (host_info64_t)&vm_stat,
                                          &count);

  if (error != KERN_SUCCESS) {
    printf("Error: Could not read vm host statistics.\n");
    return;
  }

  vm_size_t page_size;
  host_page_size(ram->host, &page_size);

  uint64_t active = (uint64_t)vm_stat.active_count * page_size;
  uint64_t wired = (uint64_t)vm_stat.wire_count * page_size;
  uint64_t compressed = (uint64_t)vm_stat.compressor_page_count * page_size;

  uint64_t used = active + wired + compressed;
  ram->used_percent = (double)used / (double)ram->total_bytes * 100.0;
  if (ram->used_percent > 100) ram->used_percent = 100;

  // Swap usage via sysctl
  struct xsw_usage swap;
  size_t swap_len = sizeof(swap);
  if (sysctlbyname("vm.swapusage", &swap, &swap_len, NULL, 0) == 0) {
    ram->swap_used_mb = (int)(swap.xsu_used / (1024 * 1024));
    ram->swap_total_mb = (int)(swap.xsu_total / (1024 * 1024));
  }

  // Memory pressure (simplified: >80% = high, >60% = warn)
  ram->pressure = ram->used_percent;
}
