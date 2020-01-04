module Config
  JOBS_CONFIG = JSON.parse(File.read('config/builds.json'))
  BUILD_LIST = JOBS_CONFIG['builds']
  WORKBOARD_LIST = JOBS_CONFIG['boards']
end
