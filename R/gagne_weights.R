#' Gagne Combined Comorbidity Score Weights
#'
#' Returns the per-condition weights of the Gagne combined comorbidity score, as
#' used by García-Albéniz et al. for cohort eligibility and adjustment. These
#' are the integer weights from the official combined-comorbidity-score program
#' (the ICD-9-CM / ICD-10-CM SAS version distributed by the DrugEpi group),
#' which combines conditions from the Charlson and Elixhauser systems. Two
#' conditions carry a **negative** weight (HIV/AIDS and hypertension).
#'
#' @details
#' Pass the result to [comorbidity_score()] together with a data frame of 0/1
#' indicators for these 20 conditions. The condition (column) names are:
#'
#' `alcohol_abuse`, `any_tumor`, `cardiac_arrhythmias`,
#' `chronic_pulmonary_disease`, `coagulopathy`, `complicated_diabetes`,
#' `congestive_heart_failure`, `deficiency_anemia`, `dementia`,
#' `fluid_and_electrolyte_disorders`, `hiv_aids`, `hemiplegia`, `hypertension`,
#' `liver_disease`, `metastatic_cancer`, `peripheral_vascular_disease`,
#' `psychosis`, `pulmonary_circulation_disorders`, `renal_failure`,
#' `weight_loss`.
#'
#' Mapping ICD-9/ICD-10 diagnosis codes to these indicators is out of scope for
#' this package; use the official Gagne SAS program or a mapping package such as
#' [comorbidity](https://CRAN.R-project.org/package=comorbidity) to build the
#' flags, then score them here.
#'
#' @return A named integer vector of the 20 condition weights.
#'
#' @seealso [comorbidity_score()], which consumes these weights.
#'
#' @references
#' Gagne JJ, Glynn RJ, Avorn J, Levin R, Schneeweiss S. A combined comorbidity
#' score predicted mortality in elderly patients better than existing scores.
#' *J Clin Epidemiol.* 2011;64(7):749-759. \doi{10.1016/j.jclinepi.2010.10.004}
#'
#' Sun JW, Rogers JR, Her Q, et al. Adaptation and validation of the combined
#' comorbidity score for ICD-10-CM. *Med Care.* 2017;55(12):1046-1051.
#' \doi{10.1097/MLR.0000000000000824}
#'
#' @export
#'
#' @examples
#' gagne_weights()
#'
#' people <- data.frame(
#'   metastatic_cancer = c(0, 1),
#'   congestive_heart_failure = c(1, 0),
#'   hypertension = c(1, 1)
#' )
#' # Only the supplied columns contribute; hypertension carries weight -1.
#' comorbidity_score(people, gagne_weights()[names(people)])
gagne_weights <- function() {
  c(
    metastatic_cancer = 5L,
    congestive_heart_failure = 2L,
    dementia = 2L,
    renal_failure = 2L,
    weight_loss = 2L,
    hemiplegia = 1L,
    alcohol_abuse = 1L,
    any_tumor = 1L,
    cardiac_arrhythmias = 1L,
    chronic_pulmonary_disease = 1L,
    coagulopathy = 1L,
    complicated_diabetes = 1L,
    deficiency_anemia = 1L,
    fluid_and_electrolyte_disorders = 1L,
    liver_disease = 1L,
    peripheral_vascular_disease = 1L,
    psychosis = 1L,
    pulmonary_circulation_disorders = 1L,
    hiv_aids = -1L,
    hypertension = -1L
  )
}
