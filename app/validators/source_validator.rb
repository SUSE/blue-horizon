# frozen_string_literal: true

# runs terraform validate with a memoized Terraform instance
class SourceValidator < ActiveModel::Validator
  def validate(record)
    error_msg = terraform.validate(true)
    record.errors[:terraform_syntax] << error_msg if error_msg
  end

  private

  def terraform
    @terraform ||= Terraform.new
  end
end