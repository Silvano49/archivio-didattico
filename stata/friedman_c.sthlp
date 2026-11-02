{smcl}
{* *! version 1.0.0 28aug2026}{...}
{vieweralsosee "friedman_c" "help friedman_c"}{...}
{viewerjumpto "Syntax" "friedman_c##syntax"}{...}
{viewerjumpto "Description" "friedman_c##description"}{...}
{viewerjumpto "When to use" "friedman_c##when"}{...}
{viewerjumpto "Algorithm" "friedman_c##algorithm"}{...}
{viewerjumpto "P-values" "friedman_c##pvalues"}{...}
{viewerjumpto "Null hypothesis" "friedman_c##null"}{...}
{viewerjumpto "Kendall's W" "friedman_c##kendall"}{...}
{viewerjumpto "Missing values and ties" "friedman_c##missing"}{...}
{viewerjumpto "Returned results" "friedman_c##results"}{...}
{viewerjumpto "Examples" "friedman_c##examples"}{...}
{viewerjumpto "Remarks" "friedman_c##remarks"}{...}

{title:Title}

{phang}
{bf:friedman_c} {hline 2} Friedman test for repeated measures in wide format,
with Kendall's W and optional exact permutation p-value

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:friedman_c} {it:varlist} {ifin} [{cmd:,} {opt exact}]

{pstd}
{it:varlist} contains the repeated measurements or experimental conditions.
Each observation corresponds to one subject (or block), and each variable
corresponds to one time point, condition, or treatment.

{pstd}
For example, with measurements at baseline, 8 weeks, and 16 weeks:

{phang2}{cmd:. friedman_c y0 y8 y16}

{phang2}{cmd:. friedman_c y0 y8 y16, exact}

{marker description}{...}
{title:Description}

{pstd}
{cmd:friedman_c} performs the Friedman rank test for matched or repeated
measurements stored in wide format. It is the nonparametric analogue of a
one-way repeated-measures ANOVA when the aim is to compare three or more
related conditions or time points.

{pstd}
The command reports:

{phang2}- the number of selected observations;

{phang2}- the number of complete subjects included in the analysis;

{phang2}- the number of subjects excluded because of missing values;

{phang2}- mean ranks and rank sums for each condition;

{phang2}- the tie-corrected Friedman chi-squared statistic;

{phang2}- the asymptotic chi-squared p-value;

{phang2}- Kendall's coefficient of concordance W;

{phang2}- the tie-correction factor;

{phang2}- and, if {cmd:exact} is specified and the number of permutations is
computationally manageable, an exact permutation p-value.

{marker when}{...}
{title:When to use the Friedman test}

{pstd}
The Friedman test is appropriate when the same subjects are observed under
three or more related conditions or at three or more time points and the
outcome can meaningfully be ranked.

{pstd}
Typical applications include repeated clinical scores, ordinal scales,
Likert-type outcomes, or continuous outcomes for which a rank-based analysis
is preferred.

{pstd}
The observations (subjects or blocks) should be independent of one another,
whereas the repeated measurements within the same subject are intentionally
related.

{pstd}
The test does not require normality of the raw measurements. It does,
however, require that the measurements be at least ordinal, because the
analysis is based on within-subject ranks.

{pstd}
With only two related conditions, the natural rank-based alternative is the
Wilcoxon signed-rank test rather than the Friedman test.

{marker algorithm}{...}
{title:Summary of the algorithm}

{pstd}
For each complete subject, {cmd:friedman_c} ranks the values across the k
conditions. The smallest value receives rank 1 and the largest receives rank
k. Tied values receive their average rank.

{pstd}
The ranks are then summed separately for each condition. If the null
hypothesis is true, the rank sums should be relatively similar across
conditions. Large differences among rank sums produce a large Friedman test
statistic.

{pstd}
Ignoring ties for notation, the classical Friedman statistic is

{p 8 12 2}
Q = 12/[n k (k+1)] * sum(R_j^2) - 3 n (k+1),

{pstd}
where n is the number of complete subjects, k is the number of conditions,
and R_j is the rank sum for condition j.

{pstd}
{cmd:friedman_c} applies the standard correction for ties before reporting the
final statistic.

{marker pvalues}{...}
{title:Asymptotic and exact p-values}

{pstd}
The command can report two different p-values for the same observed Friedman
statistic.

{dlgtab:Asymptotic p-value}

{pstd}
The default p-value, labelled {it:P-value (chi-square)}, uses the large-sample
approximation

{p 8 12 2}
Q approximately follows a chi-squared distribution with k-1 degrees of freedom.

{pstd}
This approximation is usually adequate when the number of subjects is not
very small. It is fast and remains the conventional result most commonly
reported in standard software.

{dlgtab:Exact permutation p-value}

{pstd}
If {cmd:exact} is specified, the command constructs the null distribution by
permuting the condition labels within each subject. Under the null hypothesis,
the repeated measurements are exchangeable across the condition labels.

{pstd}
For k conditions there are k! possible label permutations per subject. With n
complete subjects, the full permutation space contains

{p 8 12 2}
(k!)^n

{pstd}
configurations. When this number does not exceed the internal computational
limit, {cmd:friedman_c} enumerates the complete permutation space and reports
an exact permutation p-value.

{pstd}
The exact p-value is therefore not a Monte Carlo approximation: when it is
reported, all admissible permutations have been enumerated.

{pstd}
For small samples, particularly when n is below about 10 or when many ties are
present, the exact permutation p-value is generally preferable because the
chi-squared approximation may be less accurate. For larger samples the
asymptotic p-value is usually sufficient and the full permutation space may be
prohibitively large.

{pstd}
The two p-values answer the same inferential question but use different null
distributions: an asymptotic chi-squared approximation versus the exact
permutation distribution conditional on the observed within-subject values.

{marker null}{...}
{title:What hypothesis is tested?}

{pstd}
The Friedman test evaluates whether the distributions of the repeated
measurements are the same across the k conditions, in the sense relevant to a
rank-based comparison.

{pstd}
Operationally, the null hypothesis implies that no condition tends to receive
systematically higher or lower within-subject ranks than the others.

{pstd}
A small p-value provides evidence that at least one condition differs from the
others. It does not identify which pair or pairs of conditions differ.

{pstd}
If pairwise follow-up comparisons are required, appropriate matched-pair tests
(such as the Wilcoxon signed-rank test) should be used, with adjustment for
multiple comparisons when relevant.

{pstd}
The p-value is not the probability that the null hypothesis is true, nor the
probability that the observed result is due to chance. It quantifies how
unusual a Friedman statistic at least as extreme as the observed one would be
under the null model used for the calculation.

{marker kendall}{...}
{title:Kendall's W}

{pstd}
{cmd:friedman_c} reports Kendall's coefficient of concordance W as a
standardized measure of the strength of the overall rank pattern across
conditions.

{pstd}
For the Friedman statistic reported by the command,

{p 8 12 2}
W = Q / [n (k-1)].

{pstd}
W ranges from 0 to 1.

{phang2}{bf:W = 0} indicates little or no common ordering of the conditions
across subjects.

{phang2}{bf:W = 1} indicates perfect concordance: subjects rank the conditions
in exactly the same way.

{pstd}
In the Friedman setting, W is often used as an omnibus effect-size measure.
It should be interpreted primarily as the degree of concordance or systematic
separation of the condition ranks, rather than by rigid universal cutoffs such
as "small", "medium", or "large".

{pstd}
W has no direction. If the direction of change between specific pairs of time
points is of interest, a pairwise effect size such as the rank-biserial
correlation may be more informative.

{marker missing}{...}
{title:Missing values and ties}

{pstd}
The Friedman test requires a complete set of repeated measurements for each
subject included in the analysis. {cmd:friedman_c} therefore uses listwise
exclusion: a subject with a missing value in any variable of {it:varlist} is
excluded from the test.

{pstd}
The command explicitly reports how many selected observations were excluded
for missing data.

{pstd}
Ties within a subject are assigned average ranks. The Friedman statistic is
then corrected for ties. The reported tie-correction factor equals 1 when no
ties are present and decreases as ties become more frequent.

{pstd}
The exact permutation procedure preserves the observed within-subject values,
and therefore preserves the tie structure of the data.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:friedman_c} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(N_selected)}}number of observations selected by {cmd:if}/{cmd:in}{p_end}
{synopt:{cmd:r(N)}}number of complete subjects analysed{p_end}
{synopt:{cmd:r(N_excluded)}}number of selected subjects excluded for missing values{p_end}
{synopt:{cmd:r(k)}}number of repeated conditions or time points{p_end}
{synopt:{cmd:r(df)}}degrees of freedom, k-1{p_end}
{synopt:{cmd:r(chi2)}}tie-corrected Friedman statistic{p_end}
{synopt:{cmd:r(p)}}asymptotic chi-squared p-value{p_end}
{synopt:{cmd:r(p_asym)}}asymptotic chi-squared p-value{p_end}
{synopt:{cmd:r(kendall_w)}}Kendall's W{p_end}
{synopt:{cmd:r(tie_correction)}}tie-correction factor{p_end}
{synopt:{cmd:r(ranks)}}matrix containing mean ranks and rank sums{p_end}

{pstd}
If {cmd:exact} is requested and the exact calculation is performed, the
following are also stored:

{synopt:{cmd:r(p_exact)}}exact permutation p-value{p_end}
{synopt:{cmd:r(permutations)}}number of permutations enumerated{p_end}
{synopt:{cmd:r(extreme)}}number of permuted statistics at least as extreme as the observed statistic{p_end}

{marker examples}{...}
{title:Examples}

{pstd}
Three repeated measurements stored in wide format:

{phang2}{cmd:. friedman_c score0 score1 score2}

{pstd}
Request the exact permutation p-value:

{phang2}{cmd:. friedman_c score0 score1 score2, exact}

{pstd}
Restrict the analysis to a subgroup:

{phang2}{cmd:. friedman_c score0 score1 score2 if group==1, exact}

{pstd}
Inspect stored results:

{phang2}{cmd:. return list}

{marker remarks}{...}
{title:Remarks}

{pstd}
A statistically significant Friedman test is an omnibus result. It should not
be interpreted as evidence that all pairs of conditions differ.

{pstd}
With very small samples, graphical display of individual trajectories and
simple descriptive summaries are often valuable complements to the test.

{pstd}
When the analysis is exploratory, particular emphasis should be placed on the
observed pattern of changes, Kendall's W, and the individual data rather than
on the p-value alone.

{pstd}
The exact option is especially useful in small samples because it avoids
relying on the asymptotic chi-squared approximation. However, exact enumeration
becomes computationally expensive as either the number of conditions or the
number of subjects increases.

{title:Author}

{pstd}
User-written command.
{pstd}
Silvano Andorno and ChatGPT (OpenAI)

