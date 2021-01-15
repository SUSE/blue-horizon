# frozen_string_literal: true

# Authorize access to steps
module AuthorizationHelper
  def can(path)
    result =
      session_check(path) &&
      user_logged_check(path) &&
      terraform_action_check(path) &&
      flow_restriction_checks(path)
    logger.debug "AUTH: #{result ? 'can' : 'cannot'} access #{path}"
    return result
  end

  def check_and_alert(path)
    session_check_flash(path) &&
      user_logged_check_flash(path) &&
      terraform_action_check_flash(path) &&
      flow_restriction_checks_flash(path)
  end

  def active_session?
    session_id = session[:session_id]
    active_session_id = KeyValue.get(:active_session_id)

    # first request - allowed
    return true if !active_session_id && !session_id

    if !active_session_id && session_id
      # 2nd request - lock it down
      set_session!
      return true
    else
      session_id == active_session_id
    end
  end

  def set_session!
    KeyValue.set(:active_session_id, session[:session_id])
    KeyValue.set(:active_session_ip, request.remote_ip)
  end

  private

  def session_check(path)
    case path
    when welcome_path, reset_session_path
      true
    else
      active_session?
    end
  end

  def user_logged_check(path)
    case path
    when welcome_path, login_path
      true
    else
      user_logged?
    end
  end

  def terraform_action_check(path)
    case path
    when welcome_path, send_current_status_deploy_path
      true
    else
      !terraform_running?
    end
  end

  def flow_restriction_checks(path)
    case path
    when plan_path
      return all_variables_are_set?
    when deploy_path
      plan_exists?
    when wrapup_path, download_path
      plan_exists? && apply_log_exists?
    else
      true
    end
  end

  def session_check_flash(path)
    return true if session_check(path)

    flash[:error] = t('non_active_session')
    false
  end

  def user_logged_check_flash(path)
    return true if user_logged_check(path)

    flash[:error] = t('non_user_logged')
    false
  end

  def terraform_action_check_flash(path)
    return true if terraform_action_check(path)

    flash[:error] = t('flash.terraform_is_running')
    false
  end

  def flow_restriction_checks_flash(path)
    return true if flow_restriction_checks(path)

    flash[:error] = t('flash.unauthorized')
    false
  end

  def all_variables_are_set?
    variables = Variable.load

    return false if variables.is_a?(Hash) && variables[:error]

    variables.attributes.all? do |key, value|
      variables.type(key) == 'bool' ||
        !variables.required?(key) ||
        value.present?
    end
  end

  def export_file_exists?(filename)
    path = Rails.configuration.x.source_export_dir.join(filename)
    File.exist?(path)
  rescue StandardError
    false
  end

  def plan_exists?
    export_file_exists?('current_plan')
  end

  def apply_log_exists?
    export_file_exists? Terraform.statefilename
  end

  def terraform_running?
    KeyValue.get(:active_terraform_action).present?
  end

  def user_logged?
    KeyValue.get(:active_logged_user).present?
  end
end
