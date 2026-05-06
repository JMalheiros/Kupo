# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :set_user

  def edit
    @setting = Setting.for_edit(@user)
    render Views::Admin::Settings::Form.new(setting: @setting, user: @user)
  end

  def update
    @setting = Setting.for(@user)

    Setting.transaction do
      @setting.update!(setting_params)
      @user.update!(api_keys_params)
    end

    redirect_to root_url
  rescue ActiveRecord::RecordInvalid
    Setting.build_missing_api_keys(@user)
    render Views::Admin::Settings::Form.new(setting: @setting, user: @user), status: :unprocessable_entity
  end

  private

  def set_user
    @user = Current.user
  end

  def setting_params
    params.require(:setting).permit(:llm_provider, :llm_model, :content_review_prompt, :seo_review_prompt, :translation_prompt)
  end

  def api_keys_params
    if params[:user].present?
      params.require(:user).permit(api_keys_attributes: [ :id, :provider, :api_key, :url ])
    else
      {}
    end
  end
end
