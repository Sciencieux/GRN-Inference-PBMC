# GRN Inference Comparison on PBMC Datasets

- This is a summarised report for The University of Manchester dissertation _Evaluating the Performance of Gene Regulatory Network Inference Methods for Single Cell Multi-omics Data_. 
- Author __Boyang Xiao__
- This report details the performance evaluation of four gene regulatory network inference algorithms, DIRECT-NET, SCODE, FigR, and Regdiffusion, using two different single-cell multi-omics datasets, PBMC3K and PBMC10K. The performance metrics include memory usage and runtime in minutes.
- If you want to conduct relevant research, please refer to the tutorial in the reference materials. 

## PBMC3K Dataset Performance

| Method        | Memory Usage (GB) | Runtime (minutes) |
|---------------|-------------------|-------------------|
| DIRECT-NET    | 1.5               | 31.2              |
| SCODE         | 0.8               | 45.6              |
| FigR          | 1.2               | 27.8              |
| Regdiffusion  | 0.9               | 22.3              |

### Highlights
- **Regdiffusion** demonstrates the lowest runtime with 22.3 minutes while consuming 0.9 GB of memory, making it the most time-efficient algorithm for the PBMC3K dataset.
- **SCODE** has the lowest memory usage at 800 MB but has the highest runtime of 45.6 minutes, indicating a trade-off between memory efficiency and speed.

## PBMC10K Dataset Performance

| Method        | Memory Usage (GB) | Runtime (minutes) |
|---------------|-------------------|-------------------|
| DIRECT-NET    | 2.5               | 62.2              |
| SCODE         | 1.2               | 91.3              |
| FigR          | 2.0               | 53.6              |
| Regdiffusion  | 1.5               | 40.7              |

### Highlights
- For the larger PBMC10K dataset, **Regdiffusion** again shows the best performance with a runtime of 40.7 minutes and memory usage of 1,500 MB, suggesting it scales well with dataset size.
- **DIRECT-NET** has the highest memory usage of 2.5 GB but offers a competitive runtime of 62.2 minutes, indicating it may be more suitable for systems with ample memory.

## Results Figures

### PBMC 3K
![image](https://github.com/user-attachments/assets/f4bc5c41-1eec-46f8-9873-1ecfac19e010)
![image](https://github.com/user-attachments/assets/32ce4215-8c15-4954-b54c-75e729b68d32)
![image](https://github.com/user-attachments/assets/ee6d2611-7c6e-44c3-99b2-5c96330eec41)


### PBMC 10K
![image](https://github.com/user-attachments/assets/10771ed9-2b6c-4357-8155-bae5d9a1c911)
![image](https://github.com/user-attachments/assets/357ed629-4e55-44eb-9418-ccabf39d396d)

## Conclusion

- **Regdiffusion** consistently shows strong performance across both datasets, indicating it is a robust choice for gene regulatory network inference tasks.
- The choice of algorithm may depend on the specific requirements of the system in terms of memory availability and time constraints.
- Further testing and consideration of other factors such as accuracy, scalability, and computational resources are recommended for practical application decisions.

Please refer to the associated source code repositories for more detailed information on the methodology and implementation of these algorithms.

# Reference

| Tool Name     | Programming Language | Method Category | Link                                                   |
|---------------|---------------------|-----------------|---------------------------------------------------------|
| DIRECT-NET    | R                   |Regression                     | [DIRECT-NET GitHub](https://github.com/zhanglhbioinfor/DIRECT-NET)    |
| FigR          | R                   |Correlation                    | [FigR GitHub](https://github.com/buenrostrolab/FigR)                  |
| SCODE         | R                   |Dynamic System                 | [SCODE GitHub](https://github.com/hmatsu1226/SCODE)                   |
| RegDiffusion  | Python              |Deep Learning                  | [RegDiffusion GitHub](https://github.com/TuftsBCB/RegDiffusion)       |

