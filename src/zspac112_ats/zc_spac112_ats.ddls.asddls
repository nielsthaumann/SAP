@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZSPAC112_ATS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_SPAC112_ATS
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_SPAC112_ATS
  association [1..1] to ZR_SPAC112_ATS as _BaseEntity on $projection.RESUMEID = _BaseEntity.RESUMEID
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
  @Semantics: {
    User.Createdby: true
  }
  CreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  CreatedAt,
  @Semantics: {
    User.Lastchangedby: true
  }
  LastChangedBy,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChanged,
  _BaseEntity
}
