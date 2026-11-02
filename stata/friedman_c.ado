program define friedman_c, rclass sortpreserve
    version 13.0

    syntax varlist(min=2 numeric) [if] [in] [, Exact]

    marksample touse, novarlist

    local k : word count `varlist'

    quietly count if `touse'
    local Nselected = r(N)

    tempvar complete
    quietly egen byte `complete' = rownonmiss(`varlist')
    quietly replace `complete' = (`complete' == `k') & `touse'

    quietly count if `complete'
    local n = r(N)
    local nexcluded = `Nselected' - `n'

    if (`n' == 0) {
        display as error "nessun soggetto con dati completi su tutte le variabili"
        exit 2000
    }

    if (`n' < 2) {
        display as error "sono necessari almeno 2 soggetti completi"
        exit 2001
    }

    * Ranghi entro soggetto
    local j = 0
    foreach vj of local varlist {
        local ++j
        tempvar r`j'
        quietly generate double `r`j'' = 1 if `complete'

        foreach vl of local varlist {
            if "`vl'" != "`vj'" {
                quietly replace `r`j'' = `r`j'' + ///
                    (`vl' < `vj') + 0.5*(`vl' == `vj') ///
                    if `complete'
            }
        }
    }

    * Statistica di Friedman non corretta per ties
    tempname sumsq Q0 C Q p_asym W tiesum
    scalar `sumsq' = 0

    local j = 0
    foreach v of local varlist {
        local ++j
        quietly summarize `r`j'' if `complete', meanonly
        scalar `sumsq' = `sumsq' + (r(sum))^2
    }

    scalar `Q0' = ///
        12/(`n'*`k'*(`k'+1))*`sumsq' - 3*`n'*(`k'+1)

    * Correzione per ties
    tempvar rowtie
    quietly generate double `rowtie' = 0 if `complete'

    foreach vj of local varlist {
        tempvar tiesize
        quietly generate double `tiesize' = 0 if `complete'

        foreach vl of local varlist {
            quietly replace `tiesize' = `tiesize' + ///
                (`vl' == `vj') if `complete'
        }

        quietly replace `rowtie' = `rowtie' + ///
            (`tiesize'^2 - 1) if `complete'
    }

    quietly summarize `rowtie' if `complete', meanonly
    scalar `tiesum' = r(sum)

    scalar `C' = 1 - `tiesum'/(`n'*(`k'^3 - `k'))

    if (`C' <= 0) {
        display as error ///
            "impossibile calcolare Friedman: nessuna variabilita' nei ranghi entro soggetto"
        exit 498
    }

    scalar `Q' = `Q0'/`C'
    scalar `p_asym' = chi2tail(`k'-1, `Q')
    scalar `W' = `Q'/(`n'*(`k'-1))

    if (`W' < 0 & `W' > -1e-12) scalar `W' = 0
    if (`W' > 1 & `W' < 1+1e-12) scalar `W' = 1

    * Tabella dei ranghi
    tempname M
    matrix `M' = J(`k', 2, .)

    local j = 0
    foreach v of local varlist {
        local ++j
        quietly summarize `r`j'' if `complete', meanonly
        matrix `M'[`j',1] = r(mean)
        matrix `M'[`j',2] = r(sum)
    }

    matrix colnames `M' = Mean_rank Sum_rank
    matrix rownames `M' = `varlist'

    * P-value esatto per permutazione
    tempname p_exact nperm extreme
    scalar `p_exact' = .
    scalar `nperm' = .
    scalar `extreme' = .

    if ("`exact'" != "") {
        local fact = 1
        forvalues z = 2/`k' {
            local fact = `fact' * `z'
        }

        scalar `nperm' = (`fact')^`n'

        if (`nperm' > 5000000) {
            display as text _newline ///
                "Nota: p-value esatto non calcolato; numero di permutazioni = " ///
                as result %12.0fc `nperm' ///
                as text " (> 5,000,000)."
        }
        else {
            tempname R
            matrix `R' = J(`n', `k', .)

            local rr = 0
            quietly {
                forvalues obs = 1/`=_N' {
                    if `complete'[`obs'] {
                        local ++rr
                        local j = 0
                        foreach vj of local varlist {
                            local ++j
                            matrix `R'[`rr',`j'] = `r`j''[`obs']
                        }
                    }
                }
            }

            mata: friedman_c_exact_calc("`R'", "`Q'", "`C'", ///
                "`p_exact'", "`extreme'")
        }
    }

    display as text _newline "Test di Friedman"
    display as text "{hline 58}"
    display as text "Soggetti selezionati             = " ///
        as result %8.0f `Nselected'
    display as text "Soggetti completi analizzati     = " ///
        as result %8.0f `n'
    display as text "Soggetti esclusi per missing     = " ///
        as result %8.0f `nexcluded'
    display as text "Numero di condizioni/tempi       = " ///
        as result %8.0f `k'
    display as text "{hline 58}"

    matrix list `M', noheader format(%10.4f)

    display as text _newline ///
        "Friedman chi-squared(" as result `k'-1 as text ") = " ///
        as result %10.4f `Q'
    display as text "P-value (chi-square)          = " ///
        as result %10.6f `p_asym'

    if ("`exact'" != "" & `p_exact' < .) {
        display as text "P-value (exact permutation)   = " ///
            as result %10.6f `p_exact'
        display as text "Permutazioni enumerate        = " ///
            as result %12.0fc `nperm'
    }

    display as text "Kendall's W                   = " ///
        as result %10.4f `W'
    display as text "Tie correction factor         = " ///
        as result %10.4f `C'

    if (`n' < 10 & "`exact'" == "") {
        display as text _newline ///
            "Nota: campione molto piccolo; il p-value riportato usa " ///
            "l'approssimazione chi-quadro. Valuta l'opzione exact."
    }

    return scalar N_selected = `Nselected'
    return scalar N = `n'
    return scalar N_excluded = `nexcluded'
    return scalar k = `k'
    return scalar df = `k' - 1
    return scalar chi2 = `Q'
    return scalar p = `p_asym'
    return scalar p_asym = `p_asym'
    return scalar kendall_w = `W'
    return scalar tie_correction = `C'
    return matrix ranks = `M'

    if ("`exact'" != "" & `p_exact' < .) {
        return scalar p_exact = `p_exact'
        return scalar permutations = `nperm'
        return scalar extreme = `extreme'
    }
end

mata:
real matrix friedman_c_perms(real scalar k)
{
    real matrix P, Pold
    real rowvector oldrow, newrow
    real scalar kk, aa, pos, rr

    P = 1

    if (k > 1) {
        for (kk=2; kk<=k; kk=kk+1) {
            Pold = P
            P = J(rows(Pold)*kk, kk, .)
            rr = 1

            for (aa=1; aa<=rows(Pold); aa=aa+1) {
                oldrow = Pold[aa,.]

                for (pos=1; pos<=kk; pos=pos+1) {
                    if (pos==1) {
                        newrow = (kk, oldrow)
                    }
                    else if (pos==kk) {
                        newrow = (oldrow, kk)
                    }
                    else {
                        newrow = (oldrow[1..pos-1], kk, oldrow[pos..kk-1])
                    }

                    P[rr,.] = newrow
                    rr = rr + 1
                }
            }
        }
    }

    return(P)
}

void friedman_c_exact_calc(
    string scalar Rname,
    string scalar Qname,
    string scalar Cname,
    string scalar pename,
    string scalar exname)
{
    real matrix R, P
    real rowvector sums
    real colvector idx
    real scalar n, k, Qobs, C, np, total, extreme
    real scalar iter, i, Q0p, Qp

    R = st_matrix(Rname)
    n = rows(R)
    k = cols(R)
    Qobs = st_numscalar(Qname)
    C = st_numscalar(Cname)

    P = friedman_c_perms(k)
    np = rows(P)
    total = np^n
    extreme = 0
    idx = J(n,1,1)

    for (iter=1; iter<=total; iter=iter+1) {
        sums = J(1,k,0)

        for (i=1; i<=n; i=i+1) {
            sums = sums + R[i, P[idx[i],.]]
        }

        Q0p = 12/(n*k*(k+1))*sum(sums:^2) - 3*n*(k+1)
        Qp = Q0p/C

        if (Qp >= Qobs - 1e-12) {
            extreme = extreme + 1
        }

        for (i=n; i>=1; i=i-1) {
            idx[i] = idx[i] + 1
            if (idx[i] <= np) break
            idx[i] = 1
        }
    }

    st_numscalar(exname, extreme)
    st_numscalar(pename, extreme/total)
}
end
