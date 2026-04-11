require 'xcodeproj'

PROJECT_PATH = File.expand_path('Elevate/Elevate.xcodeproj', __dir__)
TEAM_ID              = 'FDLSN3ZJFV'
WATCH_NAME           = 'ElevateWatch'
WATCH_BUNDLE_ID      = 'com.mingus.Elevate.watchkitapp'
WATCH_DEPLOYMENT     = '10.0'

project = Xcodeproj::Project.open(PROJECT_PATH)

if project.targets.any? { |t| t.name == WATCH_NAME }
  puts "#{WATCH_NAME} target already exists — nothing to do."
  exit 0
end

app_target = project.targets.find { |t| t.name == 'Elevate' }
raise "Could not find Elevate target" unless app_target

# ── Build phases ──────────────────────────────────────────────────────────────

sources_phase   = project.new(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
sources_phase.build_action_mask = '2147483647'
sources_phase.run_only_for_deployment_postprocessing = '0'

frameworks_phase = project.new(Xcodeproj::Project::Object::PBXFrameworksBuildPhase)
frameworks_phase.build_action_mask = '2147483647'
frameworks_phase.run_only_for_deployment_postprocessing = '0'

resources_phase = project.new(Xcodeproj::Project::Object::PBXResourcesBuildPhase)
resources_phase.build_action_mask = '2147483647'
resources_phase.run_only_for_deployment_postprocessing = '0'

# ── Build settings shared across Debug/Release ────────────────────────────────

shared_settings = {
  'ASSETCATALOG_COMPILER_APPICON_NAME'           => 'AppIcon',
  'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
  'CODE_SIGN_ENTITLEMENTS'                       => "#{WATCH_NAME}/#{WATCH_NAME}.entitlements",
  'CODE_SIGN_STYLE'                              => 'Automatic',
  'CURRENT_PROJECT_VERSION'                      => '1',
  'DEVELOPMENT_TEAM'                             => TEAM_ID,
  'ENABLE_PREVIEWS'                              => 'YES',
  'GENERATE_INFOPLIST_FILE'                      => 'YES',
  'LD_RUNPATH_SEARCH_PATHS'                      => ['$(inherited)', '@executable_path/Frameworks'],
  'MARKETING_VERSION'                            => '1.0',
  'PRODUCT_BUNDLE_IDENTIFIER'                    => WATCH_BUNDLE_ID,
  'PRODUCT_NAME'                                 => '$(TARGET_NAME)',
  'SDKROOT'                                      => 'watchos',
  'SKIP_INSTALL'                                 => 'YES',
  'STRING_CATALOG_GENERATE_SYMBOLS'              => 'YES',
  'SWIFT_APPROACHABLE_CONCURRENCY'               => 'YES',
  'SWIFT_DEFAULT_ACTOR_ISOLATION'                => 'MainActor',
  'SWIFT_EMIT_LOC_STRINGS'                       => 'YES',
  'SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY' => 'YES',
  'SWIFT_VERSION'                                => '5.0',
  'TARGETED_DEVICE_FAMILY'                       => '4',
  'WATCHOS_DEPLOYMENT_TARGET'                    => WATCH_DEPLOYMENT,
}

debug_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
debug_config.name = 'Debug'
debug_config.build_settings = shared_settings.merge(
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'DEBUG $(inherited)',
  'SWIFT_OPTIMIZATION_LEVEL'            => '-Onone',
  'DEBUG_INFORMATION_FORMAT'            => 'dwarf',
  'ONLY_ACTIVE_ARCH'                    => 'YES',
)

release_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
release_config.name = 'Release'
release_config.build_settings = shared_settings.merge(
  'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym',
  'SWIFT_COMPILATION_MODE'   => 'wholemodule',
  'VALIDATE_PRODUCT'         => 'YES',
)

config_list = project.new(Xcodeproj::Project::Object::XCConfigurationList)
config_list.build_configurations << debug_config
config_list.build_configurations << release_config
config_list.default_configuration_is_visible = '0'
config_list.default_configuration_name = 'Release'

# ── Native target ─────────────────────────────────────────────────────────────

watch_target = project.new(Xcodeproj::Project::Object::PBXNativeTarget)
watch_target.name          = WATCH_NAME
watch_target.product_name  = WATCH_NAME
watch_target.product_type  = 'com.apple.product-type.application'
watch_target.build_configuration_list = config_list
watch_target.build_phases << sources_phase
watch_target.build_phases << frameworks_phase
watch_target.build_phases << resources_phase

# Product file reference
product_ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
product_ref.explicit_file_type = 'wrapper.application'
product_ref.include_in_index   = '0'
product_ref.path               = "#{WATCH_NAME}.app"
product_ref.source_tree        = 'BUILT_PRODUCTS_DIR'
project.products_group.children << product_ref
watch_target.product_reference = product_ref

# ── FileSystemSynchronizedRootGroup ───────────────────────────────────────────

watch_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
watch_group.path         = WATCH_NAME
watch_group.source_tree  = '<group>'
project.main_group.children << watch_group

# Associate the synchronized group with the watch target so Xcode discovers sources
watch_target.file_system_synchronized_groups << watch_group

# Add to project's target list
project.targets << watch_target

# ── Project-level attributes ──────────────────────────────────────────────────

project.root_object.attributes['TargetAttributes'] ||= {}
project.root_object.attributes['TargetAttributes'][watch_target.uuid] = {
  'CreatedOnToolsVersion' => '26.3'
}

# ── WatchConnectivity framework ───────────────────────────────────────────────

frameworks_group = project.frameworks_group
wc_ref = frameworks_group.files.find { |f| f.path&.include?('WatchConnectivity') }
unless wc_ref
  wc_ref = frameworks_group.new_file(
    'System/Library/Frameworks/WatchConnectivity.framework', :sdk_root
  )
  wc_ref.name = 'WatchConnectivity.framework'
end

# Add to Elevate target (phone)
unless app_target.frameworks_build_phase.files_references.include?(wc_ref)
  app_target.frameworks_build_phase.add_file_reference(wc_ref)
end

# Add to Watch target
frameworks_phase.add_file_reference(wc_ref)

# ── Dependency: Elevate → ElevateWatch ───────────────────────────────────────

proxy = project.new(Xcodeproj::Project::Object::PBXContainerItemProxy)
proxy.container_portal      = project.root_object.uuid
proxy.proxy_type            = '1'
proxy.remote_global_id_string = watch_target.uuid
proxy.remote_info           = WATCH_NAME

dep = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
dep.target       = watch_target
dep.target_proxy = proxy
app_target.dependencies << dep

# ── Embed Watch Content phase ─────────────────────────────────────────────────

embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
embed_phase.name                                  = 'Embed Watch Content'
embed_phase.build_action_mask                     = '2147483647'
embed_phase.dst_path                              = '$(CONTENTS_FOLDER_PATH)/Watch'
embed_phase.dst_subfolder_spec                    = '16'
embed_phase.run_only_for_deployment_postprocessing = '0'
app_target.build_phases << embed_phase

watch_embed_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
watch_embed_file.file_ref = product_ref
watch_embed_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
embed_phase.files << watch_embed_file

# ── Save ──────────────────────────────────────────────────────────────────────

project.save
puts "✓ Added #{WATCH_NAME} target to #{PROJECT_PATH}"
puts "  Bundle ID : #{WATCH_BUNDLE_ID}"
puts "  Min OS    : watchOS #{WATCH_DEPLOYMENT}"
puts "  Team      : #{TEAM_ID}"
puts ""
puts "Next: open Xcode, select the ElevateWatch target → Signing & Capabilities"
puts "      and register the App Groups entitlement if needed."
