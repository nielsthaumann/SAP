@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZSPAC112_ATS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_SPAC112_ATS
  provider contract transactional_query
  as projection on ZR_SPAC112_ATS
  association [1..1] to ZR_SPAC112_ATS as _BaseEntity on $projection.ResumeID = _BaseEntity.ResumeID
{
  key ResumeID,
  ResumeText,
  ResumeSkills,
  ExperienceYears,
  EducationLevel,
  Projects,
  Certifications,
  JobRole,
  RequiredSkills,
  JobExperienceRequired,
  JobDescription,
  SkillMatchScore,
  ExperienceMatch,
  EducationMatch,
  FinalScore,
  Shortlisted,
  SimilarityScore,
  AiScore,
  AiFeedback, 
  @Semantics: {
    user.createdBy: true
  }
  CreatedBy,
  @Semantics: {
    systemDateTime.createdAt: true
  }
  CreatedAt,
  @Semantics: {
    user.lastChangedBy: true
  }
  LastChangedBy,
  @Semantics: {
    systemDateTime.lastChangedAt: true
  }
  LastChangedAt,
  @Semantics: {
    systemDateTime.localInstanceLastChangedAt: true
  }
  LocalLastChanged,
  _BaseEntity
}
