# == Class: role::articlecreationworkflow
# The ArticleCreationWorkflow[1] allows to customize page creation experience for new users.
#
# [1] https://www.mediawiki.org/wiki/Extension:ArticleCreationWorkflow
class role::articlecreationworkflow {
  mediawiki::extension { 'ArticleCreationWorkflow':
      priority => $::LOAD_EARLY, # Must load before VisualEditor
  }
}
