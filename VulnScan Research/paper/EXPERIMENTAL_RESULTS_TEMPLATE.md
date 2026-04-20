# VulnScan Research Paper - Experimental Results Template

**Note:** This section is provided as a TEMPLATE. Real data should be collected through the experimental designs described below. Replace all placeholders with actual measurements from your evaluation.

---

## 6. Experimental Evaluation

### 6.1 Experimental Setup

**Testbed Configuration:**
- Hardware: [Specify: CPU cores, memory, storage type]
- Operating System: [Specify: Ubuntu 22.04 / macOS Monterey / Windows Server 2022]
- Docker Version: [Specify: 24.0.x]
- Python Runtime: [Specify: 3.11.x]
- Network: [Describe: on-premise datacenter / cloud provider / isolated lab]

**Test Dataset:**
- Number of repositories: [Specify: 150-200 projects]
- Size distribution: [Specify: 1K-100K LOC distribution]
- Programming languages: [List: Python, JavaScript, Java, Go, Ruby, PHP]
- Source: [Describe: GitHub trending repos + security-related projects + OWASP top 10]
- Ground truth: [Specify: NVD entries + manually verified vulnerabilities]

**Baseline Implementations:**
- Snyk v[X.Y.Z]: [Specify installation method]
- SonarQube v[X.Y.Z]: [Specify: Community / Developer edition]
- GitHub Advanced Security: [Specify: Which repositories included]
- Sequential Scanning: [Specify: Semgrep + TruffleHog + npm audit run sequentially]

**Metrics Measured:**
1. **Assessment Latency** (seconds): Total time from scan initiation to final report
2. **Findings Count**: Number of vulnerabilities detected per tool
3. **Deduplication Ratio** (%): Duplicate findings across multiple tools
4. **False-Positive Rate** (%): Manual validation of reported findings
5. **False-Negative Rate** (%): Ground truth vulnerabilities missed
6. **Remediation Time** (minutes): Developer time from vulnerability report to fix
7. **Resource Utilization** (%): CPU, memory, disk usage during scanning

### 6.2 Experiment 1: Latency Comparison

**Research Question:** Does asynchronous orchestration reduce assessment time compared to sequential scanning?

**Methodology:**
- Run sequential baseline on all 150 test repositories
- Run VulnScan parallel orchestration on same repositories
- Measure total assessment time (repository cloning + all tools + deduplication)
- Calculate speedup: Sequential_Time / Parallel_Time

**Results Template:**

| Repository | LOC | Sequential (s) | Parallel (s) | Speedup (x) | Tools Invoked |
|------------|-----|----------------|-------------|-------------|--------------|
| [Project 1] | [Size] | [Time] | [Time] | [2.1x] | Semgrep, TH, npm |
| [Project 2] | [Size] | [Time] | [Time] | [2.3x] | Semgrep, TH, npm, MobSF |
| ... | ... | ... | ... | ... | ... |
| **Average** | | **[Avg Seq]** | **[Avg Par]** | **[Avg Speedup]** | |

**Expected Results:**
- Average speedup: 2.0-3.0x
- Speedup increases with number of tools (2-4 tools → 1.5-3.0x)
- Memory usage: Same or lower (async multiplexing vs. sequential processes)

**Discussion:**
[Explain whether results match expectations. Discuss outliers where speedup is <1.5x or >4.0x. Correlate speedup with number of tools invoked.]

---

### 6.3 Experiment 2: False-Positive Reduction through Deduplication

**Research Question:** What percentage of findings can be eliminated through intelligent deduplication?

**Methodology:**
- Run all scanning tools independently on 150 repositories
- Count total findings: Sum_i(findings_i)
- Apply VulnScan deduplication algorithm
- Calculate deduplication ratio: (Total - Deduplicated) / Total * 100%
- Analyze deduplication by tool pair and severity level

**Results Template:**

| Tool Combination | Total Findings | Unique Findings | Dedup Ratio (%) | Severity |
|------------------|----------------|-----------------|-----------------|----------|
| Semgrep + TH | [Count] | [Count] | [%] | All |
| Semgrep + TH | [Count] | [Count] | [%] | Critical/High |
| Semgrep + npm | [Count] | [Count] | [%] | All |
| All Tools | [Count] | [Count] | [94.2%] | All |
| All Tools | [Count] | [Count] | [88.5%] | Critical/High |

**Expected Results:**
- Overall dedup ratio: 85-95%
- Higher dedup on common vulnerability types (injection, hardcoded secrets)
- Lower dedup on tool-specific findings (e.g., npm only catches dependency vulns)

**Discussion:**
[Explain which tool pairs contribute most to duplicates. Analyze severity distribution. Discuss whether deduplication introduces false negatives (unlikely with retention of max severity).]

---

### 6.4 Experiment 3: LLM-Generated Fix Quality Assessment

**Research Question:** How accurate and useful are AI-generated code fixes?

**Methodology:**
- Select 20 Critical/High vulnerabilities from test dataset
- Generate fixes using VulnScan LLM pipeline (Claude 3 Sonnet)
- Manual evaluation by 3 independent security auditors
- Metrics: Correctness, Security, Compilability, Practical Usefulness

**Evaluation Rubric:**
- **Correctness (0-2):** 0=Wrong, 1=Partially correct, 2=Fully correct
- **Security (0-2):** 0=Introduces vulnerabilities, 1=Mitigates partially, 2=Fully secure
- **Compilability (0-2):** 0=Syntax errors, 1=Requires modification, 2=Compiles as-is
- **Usefulness (0-2):** 0=Not helpful, 1=Requires significant work, 2=Ready to deploy

**Results Template:**

| Vulnerability | Type | LLM Explanation Quality | Fix Correctness | Fix Security | Compilability | Auditor Agreement |
|---|---|---|---|---|---|---|
| SQL Injection | Input validation | Good (2) | 2 | 2 | 2 | 100% |
| Hardcoded Secret | Credential exposure | Good (2) | 1 | 2 | 2 | 67% |
| [Vuln N] | [Type] | [Rating] | [Score] | [Score] | [Score] | [%] |
| **Average** | | | **1.7/2** | **1.85/2** | **1.9/2** | **89%** |

**Expected Results:**
- Average Correctness: 1.5-1.8/2 (75-90%)
- Average Security: 1.7-1.95/2 (85-97%)
- Average Compilability: 1.8-2.0/2 (90-100%)
- Auditor Agreement: 80-95%

**Discussion:**
[Identify failure modes where LLM generates incorrect fixes. Discuss hallucination types (e.g., suggesting non-existent library functions). Propose improvements for next iteration.]

---

### 6.5 Experiment 4: Developer Study - Remediation Time

**Research Question:** Does LLM-augmented remediation guidance reduce developer effort?

**Methodology:**
- Recruit 30 developers (varied experience levels)
- Divide into two groups: Control (findings only) vs. Treatment (findings + AI explanations)
- Assign 6 vulnerabilities per developer (mix of Critical/High/Medium)
- Measure time to complete fix and fix quality

**Study Protocol:**
1. Introduction to VulnScan (15 min)
2. Practice vulnerability (5 min)
3. Assessment tasks (45 min)
4. Post-study survey (15 min)

**Results Template:**

| Vulnerability Type | Group | Median Time (min) | Developers | Fix Quality Score | Confidence (1-5) |
|---|---|---|---|---|---|
| SQL Injection | Control | [Time] | [N] | [Score] | [Rating] |
| SQL Injection | Treatment | [Time] | [N] | [Score] | [Rating] |
| Hardcoded Secret | Control | [Time] | [N] | [Score] | [Rating] |
| Hardcoded Secret | Treatment | [Time] | [N] | [Score] | [Rating] |
| **Overall** | **Control** | **[Time]** | **30** | **[Score]** | **[Rating]** |
| **Overall** | **Treatment** | **[Time]** | **30** | **[Score]** | **[Rating]** |

**Statistical Analysis:**
- Paired t-test: Treatment vs. Control time (p-value)
- Effect size: Cohen's d
- Confidence intervals: 95% CI

**Expected Results:**
- Treatment group: 40-60% faster (mean time reduction)
- Treatment group: Higher fix quality (automated scoring)
- Qualitative feedback: 80%+ find AI explanations helpful

**Discussion:**
[Report statistical significance (if p < 0.05). Discuss developer feedback. Analyze why some developers benefited more than others. Identify improvement areas in LLM explanations.]

---

### 6.6 Experiment 5: Scalability and Resource Utilization

**Research Question:** How do assessment time and resource utilization scale with repository size?

**Methodology:**
- Vary repository size: 1K, 5K, 10K, 50K, 100K, 500K, 1M LOC
- Run VulnScan assessment on 10 repositories per size category
- Measure: Assessment time, peak memory usage, CPU utilization, disk I/O

**Results Template:**

| Repo Size (LOC) | Repositories (N) | Avg Time (s) | Std Dev (s) | Peak Memory (MB) | CPU Peak (%) | Disk Usage (MB) |
|---|---|---|---|---|---|---|
| 1K | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |
| 5K | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |
| 10K | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |
| 50K | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |
| 100K | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |
| 500K | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |
| 1M | 10 | [Time] | [±SD] | [Mem] | [CPU] | [Disk] |

**Time Complexity Analysis:**
- Fit polynomial: Time = a·LOC + b·log(LOC) + c
- Determine: O(n), O(n log n), or O(n²) behavior

**Expected Results:**
- Approximately linear time: Time ≈ 0.5ms/LOC (±10%)
- Memory usage: Sub-linear, peaks at 500MB-2GB for 1M LOC
- CPU: 60-90% utilization on 4-core systems

**Discussion:**
[Compare against sequential baseline. Identify bottlenecks (memory, CPU, disk I/O). Discuss whether resource limits are appropriate for container deployment.]

---

### 6.7 Experiment 6: Comparative Benchmarking

**Research Question:** How does VulnScan compare to Snyk, SonarQube, and GHAS?

**Methodology:**
- Install Snyk, SonarQube, GHAS on same test infrastructure
- Run all tools on 150 test repositories
- Standardize output to common schema
- Compare: Detection rate, false-positive rate, remediation guidance quality

**Results Template - Detection Rate:**

| Tool | Critical (N) | High (N) | Medium (N) | Low (N) | Total | Precision | Recall |
|---|---|---|---|---|---|---|---|
| Snyk | [N] | [N] | [N] | [N] | [N] | [%] | [%] |
| SonarQube | [N] | [N] | [N] | [N] | [N] | [%] | [%] |
| GHAS | [N] | [N] | [N] | [N] | [N] | [%] | [%] |
| **VulnScan** | [N] | [N] | [N] | [N] | [N] | [95%] | [92%] |
| **Union** | [N] | [N] | [N] | [N] | [N] | - | - |

**Results Template - Feature Comparison:**

| Feature | Snyk | SonarQube | GHAS | VulnScan |
|---|---|---|---|---|
| Multi-tool orchestration | ✗ | ✗ | ✗ | ✓ |
| LLM-augmented fixes | ✗ | ✗ | ✗ | ✓ (Pro+) |
| Multi-tenancy SaaS | ✓ | ✗ | Partial | ✓ |
| Open-source | ✗ | ✓ | ✗ | ✓ |
| Self-hosted option | ✗ | ✓ | ✗ | ✓ (Docker) |
| Secret scanning | ✓ | ✗ | ✓ | ✓ |
| Dependency audit | ✓ | ✗ | ✓ | ✓ |
| Mobile (Android/iOS) | ✗ | ✗ | ✗ | ✓ |
| Assessment time (avg) | [X]s | [Y]s | [Z]s | [2.5]s |

**Expected Results:**
- VulnScan recall: Similar to tool union (90-95%)
- VulnScan precision: Superior due to deduplication (92-96%)
- Assessment time: Significantly faster than sequential (2-3x)
- Unique advantage: Only tool with orchestration + LLM + open-source

**Discussion:**
[Explain why VulnScan excels (parallelization, dedup) vs. where competitors are stronger (established ecosystems, maturity). Position as complementary rather than replacement tool.]

---

### 6.8 Threats to Validity

**Internal Validity:**
- Limited developer pool (30) may not represent general population
- Laboratory setting may not reflect real-world conditions
- LLM behavior varies with API version/parameters

**External Validity:**
- Test dataset may not represent all software types
- Results may not generalize to proprietary codebases
- Docker performance may vary across cloud providers

**Construct Validity:**
- "Remediation time" may not capture true developer effort
- "Fix quality" is subjectively scored by auditors
- Deduplication semantic may miss subtle differences

**Mitigation:**
- Include sensitivity analyses
- Disclose test dataset characteristics
- Report inter-rater reliability scores
- Describe parameter settings (LLM temperature, etc.)

---

## 7. Discussion

### 7.1 Key Findings

[Synthesize results from Experiments 1-6. Highlight:
1. Parallel orchestration achieves 2.5x speedup
2. Deduplication eliminates 94.2% of duplicates
3. LLM fixes achieve 85% correctness/security
4. Developer study shows 45% time reduction
5. Scales to 1M+ LOC repositories]

### 7.2 Practical Implications

[Discuss actionable insights for practitioners:
1. Deploy VulnScan for multi-tool coordination
2. Enable AI fixes for Pro/Enterprise users
3. Use for supply chain security assessment
4. Integrate into CI/CD pipelines]

### 7.3 Research Implications

[Discuss contributions to security research:
1. Formal deduplication semantics for tool composition
2. Structured LLM prompting for security context
3. Multi-tenant architecture for SaaS security tools
4. Framework for future orchestration research]

---

## 8. Limitations and Future Work

### 8.1 Limitations

1. **Tool Coverage:** Limited to static analysis; DAST tools not included
2. **LLM Hallucination:** Generated fixes may contain security errors
3. **Test Dataset:** 150 projects may not represent all software types
4. **Scalability:** MobSF limited to one app per scan; Android/iOS only

### 8.2 Future Work

1. **Formal Verification:** Prove correctness of generated fixes using SMT solvers
2. **Extended Tool Support:** Integrate DAST (OWASP ZAP), SAST (Checkmarx)
3. **ML-based Filtering:** Train classifiers to predict false positives
4. **Privacy-preserving Assessment:** Differential privacy for vulnerability aggregation
5. **Adversarial Evaluation:** Red-teaming of LLM fix generation

---

## Instructions for Authors

1. **Conduct Experiments:** Follow methodology in Section 6.1-6.7
2. **Collect Data:** Use template tables above to record measurements
3. **Analyze Results:** Run statistical tests (t-tests, ANOVA, correlation analysis)
4. **Create Figures:** Generate line charts (latency vs. size), bar charts (tool comparison)
5. **Write Narrative:** Replace this template with actual prose explaining findings
6. **Address Limitations:** Acknowledge threats to validity
7. **Revise Introduction:** Reference actual results ("as shown in Section 6.2...")

---

## Expected Section Length

When complete, this Results & Discussion section should be 800-1000 words (approximately 15-20% of total paper).

Good luck with your evaluation! 📊
