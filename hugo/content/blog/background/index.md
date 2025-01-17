---
title: "Overview of Ahoi Attacks"
description: ""
summary: ""
date: 2024-04-04T00:04:48+02:00
lastmod: 2024-04-04T00:04:48+02:00
draft: false
weight: 50
contributors: []
pinned: false
homepage: false
slug: ahoi-overview
seo:
#  title: "" # custom title (optional)
#  description: "" # custom description (recommended)
#  canonical: "" # custom canonical URL (optional)
  noindex: false # false (default) or true
---

## Confidential Computing

Confidential computing, also referred to as trusted computing, trusted execution, or trusted execution environments (TEEs), enables users to outsource sensitive computation to untrusted cloud platforms without compromising security. To support this, hardware vendors provide trusted hardware that ensures that the user’s code and data remain protected from malicious tenants and malicious cloud service providers. 

Today, users can provision confidential computing resources with process-level abstractions with technologies like Intel SGX with cloud service providers. In this model, a single Intel SGX enclave process is isolated by the trusted hardware from other processes (e.g., other applications, operating system). 

To support a better cloud-native abstraction, there has been an increasing shift towards Confidential VMs (CVMs) where the trusted hardware provides VM-level isolation. With technologies like AMD SEV, Intel TDX, and ARM CCA users can deploy entire VMs and execute them such that they are not accessible to other tenants or the cloud service provider’s hardware (e.g., network devices) or software (e.g., hypervisor). 


## Interrupt delivery to Confidential VMs

In the CVM setting, the hypervisor is still responsible for most configuration and management tasks (e.g., memory management, scheduling), including interrupts. Ahoi attacks use notifications to break the security of CVMs. So, let’s understand how interrupt delivery, a form of notification, to CVMs typically works.

The guest OS executing inside the CVMs relies on interrupts for its operation (e.g., the guest Linux kernel requires timer interrupts for scheduling). To ensure that the guest OS continues to function, the hypervisor virtualizes the interrupt management and delivery to the CVMs. For this, the hypervisor hooks on all physical interrupts in the interrupt controller. For every interrupt, the hypervisor determines which VM should receive the interrupt, and sets up the interrupt controller to forward a virtual interrupt to the virtual CPU (vCPU). The guest OS of the CVM services the virtual interrupt by executing a handler. Finally, the handler of the guest OS acknowledges the interrupt.


## Signal Delivery to Confidential VMs

In the x86 architecture, hardware exceptions are mapped to interrupt numbers between 0-31. For example, if an application performs a divide-by-zero, the hardware raises interrupt number 0 to the OS. Then, the OS converts interrupt 0 to a signal (SIGFPE) and delivers it to the user-space application. Now, the userspace application can register a custom handler for SIGFPE. For example, in the code snippet below, the `compute_weighted` function resorts to computing a non-weighted average if the operation results in a SIGFPE. 

```c
double arr[] = {...}
double weights[] = {...}
double avg = 0
void handler() { /* compute non-weighted avg */ } 

int compute_weighted() {
  register(SIGFPE, handler)
  avg = ...      /* compute weighted avg */ 
  …
  return avg
}  
```


## Exploiting global effects of handlers

For Ahoi Attacks, an attacker can use the hypervisor to inject malicious interrupts to the victim’s vCPUs and trick it into executing the interrupt handlers. These interrupt handlers can have global effects (e.g., changing the register state in the application) that an attacker can trigger to compromise the victim's CVM. 

For example, consider an application that branches to an `auth` block based on the value of `eax`. The `int 0x80` handler changes the value of `eax` to -4. An attacker injects `int 0x80` before the test is performed as shown in the animation below. This changes the execution flow leading to successful authentication. 

![Hecker int 0x80](heckler-int80.webp)

The interrupts and signals we looked at so far trigger existing handlers that were programmed for a traditional setting where the hypervisor used to be trusted. But when used as-is in the confidential computing setting, this interface can be misused to launch an Ahoi attack. Check out our [Heckler](../../heckler/) project for more details on how we break into AMD SEV-SNP and Intel TDX to remotely log in and gain sudo access to CVMs.

Another instance of an Ahoi attack is on a new interrupt interface introduced specially for confidential computing. In particular, AMD SEV introduces a new interrupt called VMM Communication Exception (`#VC`) to facilitate functionality where the hypervisor needs to access CVM’s memory. Since such accesses are forbidden, raising a `#VC` allows AMD SEV to handle such accesses (e.g., the hypervisor can fill in the processor details with the CVM executes a cpuid instruction). But this interface is also susceptible to the same pitfall. The hypervisor can arbitrarily raise `#VC`, even when the victim does not need to send or receive any information to the hypervisor. Since the victim CVM cannot distinguish between benign and malicious `#VC`, it always executes the VC handler that copies data in and out of the CVM depending on the reason for raising the `#VC`. The hypervisor controls the reason as well, making matters worse. Check out our [WeSee](../../wesee/) project for more details on how we break into AMD SEV-SNP to perform arbitrary read, write, and code injection on CVMs.

Apart from CVMs, [Sigy](../../sigy/) another instance of an Ahoi Attack, compromises Intel SGX enclaves by using a malicious OS to arbitrary inject signals. Check out the [Sigy's](../../heckler/) project page for more details. 
