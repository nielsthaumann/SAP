@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZSPAC112_ATS'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_SPAC112_ATS
  as select from zspac112_ats
{
  key resume_id as ResumeID,
  resume_text as ResumeText,
  resume_skills as ResumeSkills,
  experience_years as ExperienceYears,
  education_level as EducationLevel,
  projects as Projects,
  certifications as Certifications,
  job_role as JobRole,
  required_skills as RequiredSkills,
  job_experience_required as JobExperienceRequired,
  job_description as JobDescription,
  skill_match_score as SkillMatchScore,
  experience_match as ExperienceMatch,
  education_match as EducationMatch,
  final_score as FinalScore,
  shortlisted as Shortlisted,
  similarity_score as SimilarityScore,
  ai_score    as AiScore,
  ai_feedback as AiFeedback, 
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.lastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed as LocalLastChanged
}
