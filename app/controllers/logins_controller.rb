# frozen_string_literal: true

require 'azurecli'

class LoginsController < ApplicationController
  def show
    @logged_account = AzureCli.new.logged_account
    if @logged_account[:logged]
      KeyValue.set(:active_logged_user, true)
    end

    respond_to do |format|
      format.html
      format.js { render :layout => false, :action => "refresh" }
      format.json do
        render json: { logged_account: @logged_account }
      end
    end
  end

  def update
    @code = AzureCli.new.login
    respond_to do |format|
      format.js { render :layout => false, :action => "refresh" }
    end
  end

  def destroy
    AzureCli.new.logout
    @logged_account = AzureCli.new.logged_account
    KeyValue.set(:active_logged_user, false)
    respond_to do |format|
      format.js { render :layout => false, :action => "refresh" }
    end
  end
end
