# FPGA Optimizations for Kyber & Dilithium (NTT/INTT)

This project aims to review and evaluate different hardware optimizations found in multiple open-source implementations of the Number Theoretic Transform (NTT) and Inverse NTT (INTT) for Kyber (ML-KEM) and Dilithium (ML-DSA).

## Baseline Verification

A base "naive" implementation of the NTT/INTT for Kyber was developed to serve as a benchmark. This baseline architecture was tested and verified using test vectors generated from the official [reference Kyber software implementation](https://github.com/pq-crystals/kyber).

## Target Implementations

This project tests, analyzes, and integrates architectural optimizations from the following open-source hardware implementations and their preceding works:
## Kyber (ML-KEM)

* [1] E. Camacho-Ruiz, P. Navarro-Torrero, and A. Cabrera Aldaya, "A Framework for designing High-Order Side-Channel Protected Hardware Implementations of ML-KEM," *IACR Transactions on Cryptographic Hardware and Embedded Systems (TCHES)*, vol. 2026, no. 2, pp. 272–295, Apr. 2026, doi: [10.46586/tches.v2026.i2.272-295]
  https://github.com/HWSec-CSIC/hope-mlkem

* [2] Y. Xing and S. Li, "A Compact Hardware Implementation of CCA-Secure Key Exchange Mechanism CRYSTALS-KYBER on FPGA"IACR Transactions on Cryptographic Hardware and Embedded Systems, Vol. 2021, No. 2, pp. 328–356.
  https://github.com/xingyf14/CRYSTALS-KYBER

## Dilithium (ML-DSA)

* [3] L. Beckwith, D.T. Nguyen, and K. Gaj, "High-Performance Hardware Implementation of CRYSTALS-Dilithium," in 2021 International Conference on Field-Programmable Technology, FPT 2021, Dec. 2021. 
  https://github.com/GMUCERG/Dilithium

* [4] G. Mao et al., "High-performance and Configurable SW/HW Co-design of Post-quantum Signature CRYSTALS-Dilithium," ACM Transactions on Reconfigurable Technology and Systems, vol. 16, no. 3, Art. no. 44, pp. 1-28, Jun. 2023.
  https://github.com/CityUHK-CALAS/SW-HW-Co-design-of-Dilithium

## RISC-V Accelerator (Kyber/Dilithium)

* [5] A. Dolmeta, M. Martina, and G. Masera, "ATHOS: A Hybrid Accelerator for PQC CRYSTALS-Algorithms Exploiting New CV-X-IF Interface," IEEE Access, vol. 12, pp. 182340-182352, Dec. 2024.
  https://github.com/edge-group-polito/ATHOS
