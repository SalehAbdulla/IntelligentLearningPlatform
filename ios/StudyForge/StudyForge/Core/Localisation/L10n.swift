//
//  L10n.swift
//  StudyForge
//
//  Typed access to user-facing copy.
//
//  WHY TYPES RATHER THAN RAW STRINGS
//  ----------------------------------
//  `NSLocalizedString("auth.login.titel", …)` — note the typo — compiles happily and
//  renders the literal key `auth.login.titel` on screen. Nothing fails; you find out
//  in a screenshot. Modelling keys as an enum moves that class of bug to the compiler,
//  and `L10nTests` additionally asserts every case resolves to a real translation, so
//  a key that exists in code but not in `Localizable.strings` is caught by a test
//  rather than by a user.
//
//  The screen code therefore never contains a localisation key as a bare string, which
//  is what makes "no hard-coded user-facing strings" (docs/04 §8) checkable rather than
//  aspirational.
//

import Foundation

/// Every user-facing string in the app, by key.
///
/// Add a case here AND the matching entry in **both** `en.lproj` and `ar.lproj` —
/// `tools/check-strings.py` fails the build if the two catalogues disagree, and
/// `L10nTests` fails if this enum and the catalogue disagree.
enum L10n: String, CaseIterable, Sendable {

    // MARK: Common
    case appName            = "common.appName"
    case commonContinue     = "common.continue"
    case commonNext         = "common.next"
    case commonSkip         = "common.skip"
    case commonCancel       = "common.cancel"
    case commonDone         = "common.done"
    case commonRetry        = "common.retry"
    case commonBack         = "common.back"
    case commonClose        = "common.close"
    case commonLoading      = "common.loading"
    case commonShowPassword = "common.showPassword"
    case commonHidePassword = "common.hidePassword"
    case commonDelete       = "common.delete"

    // MARK: A01 Splash
    case splashTagline      = "auth.splash.tagline"
    case splashChecking     = "auth.splash.checking"

    // MARK: A07 Log in
    case loginTitle         = "auth.login.title"
    case loginSubtitle      = "auth.login.subtitle"
    case loginEmail         = "auth.login.email"
    case loginPassword      = "auth.login.password"
    case loginForgot        = "auth.login.forgotPassword"
    case loginSubmit        = "auth.login.submit"
    case loginSubmitting    = "auth.login.submitting"
    case loginNoAccount     = "auth.login.noAccount"
    case loginCreateAccount = "auth.login.createAccount"
    case loginErrorTitle    = "auth.login.errorTitle"

    // MARK: A05 Sign up
    case signUpTitle          = "auth.signUp.title"
    case signUpSubtitle       = "auth.signUp.subtitle"
    case signUpName           = "auth.signUp.name"
    case signUpNameHint       = "auth.signUp.nameHint"
    case signUpEmail          = "auth.signUp.email"
    case signUpPassword       = "auth.signUp.password"
    case signUpPasswordHint   = "auth.signUp.passwordHint"
    case signUpSubmit         = "auth.signUp.submit"
    case signUpSubmitting     = "auth.signUp.submitting"
    case signUpHaveAccount    = "auth.signUp.haveAccount"
    case signUpLogIn          = "auth.signUp.logIn"
    case signUpTermsPrefix    = "auth.signUp.termsPrefix"
    case signUpTerms          = "auth.signUp.terms"
    case signUpTermsJoiner    = "auth.signUp.termsJoiner"
    case signUpPrivacy        = "auth.signUp.privacy"
    case signUpTermsUnavailable = "auth.signUp.termsUnavailable"
    case signUpErrorTitle     = "auth.signUp.errorTitle"

    // MARK: Password strength
    case strengthLabel        = "auth.strength.label"
    case strengthWeak         = "auth.strength.weak"
    case strengthFair         = "auth.strength.fair"
    case strengthStrong       = "auth.strength.strong"
    case strengthRuleLength   = "auth.strength.rule.length"
    case strengthRuleNumber   = "auth.strength.rule.number"
    case strengthRuleSymbol   = "auth.strength.rule.symbol"

    // MARK: A08 Forgot password
    case forgotTitle        = "auth.forgot.title"
    case forgotSubtitle     = "auth.forgot.subtitle"
    case forgotEmail        = "auth.forgot.email"
    case forgotSubmit       = "auth.forgot.submit"
    case forgotSubmitting   = "auth.forgot.submitting"
    case forgotSuccessTitle = "auth.forgot.successTitle"
    case forgotSuccessBody  = "auth.forgot.successBody"
    case forgotBackToLogin  = "auth.forgot.backToLogin"
    case forgotErrorTitle   = "auth.forgot.errorTitle"

    // MARK: A02–A04 Onboarding
    case onboardingSkip        = "onboarding.skip"
    case onboardingSkipHint    = "onboarding.skip.hint"
    case onboardingNext        = "onboarding.next"
    case onboardingGetStarted  = "onboarding.getStarted"
    case onboardingPageIndicator = "onboarding.pageIndicator"
    case onboardingStepIndicator = "onboarding.stepIndicator"

    case onboardingValuePropTitle = "onboarding.valueProp.title"
    case onboardingValuePropBody  = "onboarding.valueProp.body"

    case onboardingHowItWorksTitle = "onboarding.howItWorks.title"
    case onboardingHowItWorksBody  = "onboarding.howItWorks.body"
    case onboardingStepUploadTitle   = "onboarding.step.upload.title"
    case onboardingStepUploadBody    = "onboarding.step.upload.body"
    case onboardingStepGenerateTitle = "onboarding.step.generate.title"
    case onboardingStepGenerateBody  = "onboarding.step.generate.body"
    case onboardingStepPlanTitle     = "onboarding.step.plan.title"
    case onboardingStepPlanBody      = "onboarding.step.plan.body"
    case onboardingStepPractiseTitle = "onboarding.step.practise.title"
    case onboardingStepPractiseBody  = "onboarding.step.practise.body"

    case onboardingPrivacyTitle    = "onboarding.privacy.title"
    case onboardingPrivacyBody     = "onboarding.privacy.body"
    case onboardingPrivacyOnDevice = "onboarding.privacy.onDevice"
    case onboardingPrivacyCloud    = "onboarding.privacy.cloud"
    case onboardingPrivacyTraining = "onboarding.privacy.training"

    // MARK: A06 Email verification
    case verifyTitle        = "auth.verify.title"
    case verifyBody         = "auth.verify.body"
    case verifyResend       = "auth.verify.resend"
    case verifyResendIn     = "auth.verify.resendIn"
    case verifyResendSent   = "auth.verify.resendSent"
    case verifyCheckNow     = "auth.verify.checkNow"
    case verifyChecking     = "auth.verify.checking"
    case verifySpamHint     = "auth.verify.spamHint"
    case verifyWrongAddress = "auth.verify.wrongAddress"
    case verifyNotYetTitle  = "auth.verify.notYetTitle"
    case verifyNotYetBody   = "auth.verify.notYetBody"

    // MARK: Session
    case sessionSignedInAs        = "session.signedInAs"
    case sessionSignOut           = "session.signOut"
    case sessionHomeTitle         = "session.homePlaceholder.title"
    case sessionHomeBody          = "session.homePlaceholder.body"

    // MARK: Home placeholder (capability read-out)
    case homeCapabilitiesHeading = "home.capabilities.heading"
    case homeRoleLabel           = "home.role.label"
    case homePlanLabel           = "home.plan.label"
    case homeTutorStudioLabel    = "home.tutorStudio.label"
    case homeStudyGroupsLabel    = "home.studyGroups.label"
    case homeAvailable           = "home.available"
    case homeUnavailable         = "home.unavailable"

    // MARK: B01 Profile setup — academic
    case profileAcademicTitle                 = "profile.academic.title"
    case profileAcademicSubtitle              = "profile.academic.subtitle"
    case profileAcademicUniversity            = "profile.academic.university"
    case profileAcademicUniversityPlaceholder = "profile.academic.universityPlaceholder"
    case profileAcademicMajor                 = "profile.academic.major"
    case profileAcademicMajorHint             = "profile.academic.majorHint"
    case profileAcademicYear                  = "profile.academic.year"
    case profileAcademicCourses               = "profile.academic.courses"
    case profileAcademicCoursesEmpty          = "profile.academic.coursesEmpty"
    case profileAcademicSubmitting            = "profile.academic.submitting"
    case profileAcademicErrorUniversity       = "profile.academic.error.university"
    case profileAcademicErrorMajor            = "profile.academic.error.major"
    case profileAcademicErrorYear             = "profile.academic.error.year"
    case profileAcademicErrorCourses          = "profile.academic.error.courses"

    // MARK: Profile wizard (shared across steps)

    /// "Step %d of %d" — one key for the whole wizard. Per-step copies would be the same
    /// sentence three times, and the first one edited would be the only one that changed.
    case profileStep = "profile.step"

    // MARK: B02 Profile setup — learning style
    case profileLearningStyleTitle           = "profile.learningStyle.title"
    case profileLearningStyleSubtitle        = "profile.learningStyle.subtitle"
    case profileLearningStyleSubmitting      = "profile.learningStyle.submitting"
    case profileLearningStyleError           = "profile.learningStyle.error"

    case profileStyleVisualTitle             = "profile.learningStyle.visual.title"
    case profileStyleVisualPreview           = "profile.learningStyle.visual.preview"
    case profileStyleVerbalTitle             = "profile.learningStyle.verbal.title"
    case profileStyleVerbalPreview           = "profile.learningStyle.verbal.preview"
    case profileStyleReadWriteTitle          = "profile.learningStyle.readWrite.title"
    case profileStyleReadWritePreview        = "profile.learningStyle.readWrite.preview"
    case profileStyleKinestheticTitle        = "profile.learningStyle.kinesthetic.title"
    case profileStyleKinestheticPreview      = "profile.learningStyle.kinesthetic.preview"

    // MARK: B03 Profile setup — study goals
    case profileStudyGoalsTitle              = "profile.studyGoals.title"
    case profileStudyGoalsSubtitle           = "profile.studyGoals.subtitle"
    case profileStudyGoalsSubmitting         = "profile.studyGoals.submitting"
    case profileStudyGoalsFinish             = "profile.studyGoals.finish"
    case profileStudyGoalsHoursLabel         = "profile.studyGoals.hoursLabel"
    case profileStudyGoalsGradeLabel         = "profile.studyGoals.gradeLabel"
    case profileStudyGoalsGradeError         = "profile.studyGoals.gradeError"

    /// The four plural categories of the hours readout — see `WeekHoursReadout` for why a
    /// count needs four keys in Arabic and two in English.
    case profileStudyGoalsHoursOne           = "profile.studyGoals.hours.one"
    case profileStudyGoalsHoursTwo           = "profile.studyGoals.hours.two"
    case profileStudyGoalsHoursFew           = "profile.studyGoals.hours.few"
    case profileStudyGoalsHoursMany          = "profile.studyGoals.hours.many"

    // MARK: B04 Profile setup — complete
    case profileCompleteTitle                = "profile.complete.title"
    case profileCompleteSubtitle             = "profile.complete.subtitle"
    case profileCompleteSummaryHeading       = "profile.complete.summaryHeading"
    case profileCompleteGoToDashboard        = "profile.complete.goToDashboard"

    /// The summary-row labels, one per field the wizard may have collected.
    case profileCompleteUniversity           = "profile.complete.university"
    case profileCompleteMajor                = "profile.complete.major"
    case profileCompleteYear                 = "profile.complete.year"
    case profileCompleteCourses              = "profile.complete.courses"
    case profileCompleteLearningStyle        = "profile.complete.learningStyle"
    case profileCompleteHours                = "profile.complete.hours"
    case profileCompleteGrade                = "profile.complete.grade"

    // MARK: B07 Profile edit
    case profileEditTitle          = "profile.edit.title"
    case profileEditName           = "profile.edit.name"
    case profileEditNameHint       = "profile.edit.nameHint"
    case profileEditNameError      = "profile.edit.nameError"
    case profileEditSave           = "profile.edit.save"
    case profileEditSaving         = "profile.edit.saving"
    case profileEditAvatarNote     = "profile.edit.avatarNote"
    case profileEditDiscardTitle   = "profile.edit.discardTitle"
    case profileEditDiscardMessage = "profile.edit.discardMessage"
    case profileEditDiscard        = "profile.edit.discard"
    case profileEditKeepEditing    = "profile.edit.keepEditing"

    // MARK: B06 Profile view
    case profileViewTitle           = "profile.view.title"
    case profileViewStudiesHeading  = "profile.view.studiesHeading"
    case profileViewPlanHeading     = "profile.view.planHeading"
    case profileViewProgressTitle   = "profile.view.progressTitle"
    case profileViewProgressBody    = "profile.view.progressBody"

    // MARK: F02 Material library
    case libraryTitle             = "library.title"
    case librarySearchPlaceholder = "library.searchPlaceholder"
    case libraryEmptyTitle        = "library.emptyTitle"
    case libraryEmptyBody         = "library.emptyBody"
    case libraryNoMatchesTitle    = "library.noMatchesTitle"
    case libraryNoMatchesBody     = "library.noMatchesBody"

    /// Where a material came from — one name per `MaterialSource`.
    case materialSourcePdf        = "material.source.pdf"
    case materialSourceImage      = "material.source.image"
    case materialSourceScan       = "material.source.scan"
    case materialSourceLink       = "material.source.link"
    case materialSourceText       = "material.source.text"

    // MARK: F02 Import
    case importTitle              = "import.title"
    case importSourceTextTitle    = "import.sourceText.title"
    case importSourceTextDetail   = "import.sourceText.detail"
    case importSourcePdfTitle     = "import.sourcePdf.title"
    case importSourcePdfDetail    = "import.sourcePdf.detail"
    case importNameLabel          = "import.nameLabel"
    case importNamePlaceholder    = "import.namePlaceholder"
    case importTextLabel          = "import.textLabel"
    case importTextHint           = "import.textHint"
    case importTagsLabel          = "import.tagsLabel"
    case importTagsHint           = "import.tagsHint"
    case importSubmit             = "import.submit"
    case importSubmitting         = "import.submitting"
    case importErrorName          = "import.error.name"
    case importErrorText          = "import.error.text"
    case importErrorUnreadable    = "import.error.unreadable"
    case importErrorNoText        = "import.error.noText"
}

// MARK: - Resolution

extension L10n {

    /// The translated string, resolved from the main bundle.
    ///
    /// `NSLocalizedString` rather than `String(localized:)`: the latter depends on
    /// compile-time string extraction, and this project's catalogue is a plain
    /// `.strings` file that `tools/check-strings.py` validates. Resolving the same way
    /// in code and in the gate keeps the two honest about each other.
    var string: String {
        NSLocalizedString(rawValue, comment: "")
    }

    /// The translated string with format arguments applied.
    ///
    /// - Warning: `String(format:)` does not type-check its arguments. `%@` given an
    ///   `Int` is a runtime crash, not a compile error — which is why
    ///   `tools/check-strings.py` verifies that every language uses the same
    ///   placeholder types as English. Passing the wrong type still compiles here; the
    ///   catalogue gate is what catches the language-drift half of that risk.
    func string(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(rawValue, comment: ""), arguments: arguments)
    }
}

