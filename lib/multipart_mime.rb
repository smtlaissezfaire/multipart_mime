require 'rubygems'
require 'net/http' unless Object.const_defined?(:Net) && Net.const_defined?(:HTTP)
require 'mime/types'
require 'base64'
require 'cgi'

module MultiPartMime
  def multipart_params=(param_hash={})
    boundary_token = [Array.new(8) {rand(256)}].join
    self.content_type = "multipart/form-data; boundary=#{boundary_token}"
    boundary_marker = "--#{boundary_token}\r\n"
    
    self.body = param_hash.map do |param_name, param_value|
      boundary_marker + case param_value
      when Array
        file_to_multipart(param_name, param_value[0], param_value[1])
      else
        text_to_multipart(param_name, param_value.to_s)
      end
    end.join('') + "--#{boundary_token}--\r\n"
  end

private

  def file_to_multipart(key, file_content, filename)
    mime_types = MIME::Types.of(filename)
    mime_type = mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
    part = %Q|Content-Disposition: form-data; name="#{key}"; filename="#{filename}"\r\n|
    part += "Content-Transfer-Encoding: binary\r\n"
    part += "Content-Type: #{mime_type}\r\n\r\n#{file_content}\r\n"
  end

  def text_to_multipart(key,value)
    "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n#{value}\r\n"
  end
end

class Net::HTTP::Post
  include MultiPartMime
end