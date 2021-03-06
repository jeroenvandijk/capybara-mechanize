# frozen_string_literal: true

class Capybara::Mechanize::Form < Capybara::RackTest::Form
  def params(button)
    return super unless use_mechanize?

    node = {}
    # Create a fake form
    class << node
      def search(*_args); []; end
    end

    node['method'] = button && button['formmethod']

    node['method'] ||= (respond_to?(:request_method, true) ? request_method : method).to_s.upcase

    node['enctype'] = multipart? ? 'multipart/form-data' : 'application/x-www-form-urlencoded'

    @m_form = Mechanize::Form.new(node, nil, form_referer)

    super

    @m_form
  end

  private

  def merge_param!(params, key, value)
    return super unless use_mechanize?

    # Adding a nil value here will result in the form element existing with the empty string as its value.
    # Instead don't add the form element at all.
    return params if value.is_a? NilUploadedFile

    if value.is_a? Rack::Test::UploadedFile
      @m_form.enctype = 'multipart/form-data'

      ul = Mechanize::Form::FileUpload.new({ 'name' => key.to_s }, value.original_filename)
      ul.mime_type = value.content_type
      ul.file_data = (value.rewind; value.read)

      @m_form.file_uploads << ul

      return params
    end

    @m_form.fields << Mechanize::Form::Field.new({ 'name' => key.to_s }, value)

    params
  end

  def use_mechanize?
    driver.remote?(native['action'].to_s)
  end

  def form_referer
    Mechanize::Page.new URI(driver.current_url)
  end
end
