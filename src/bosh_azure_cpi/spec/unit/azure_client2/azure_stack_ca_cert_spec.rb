require 'spec_helper'

describe Bosh::AzureCloud::AzureClient2 do
  let(:logger) { Bosh::Clouds::Config.logger }
  let(:azure_stack_domain) { "fake-azure-stack-domain" }
  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)
  end

  describe "#azure_stack_ca_cert" do
    context "when ssl validation is skipped" do
      let(:azure_client2) {
        Bosh::AzureCloud::AzureClient2.new(
          mock_cloud_options["properties"]["azure"].merge!({
            "environment" => "AzureStack",
            "azure_stack" => {
              "domain"              => azure_stack_domain,
              "resource"            => "fake-resource",
              "skip_ssl_validation" => true
            }
          }),
          logger
        )
      }
      let(:uri) { URI("https://fake-host") }

      it "should use the mode VERIFY_NONE" do
        expect(http).to receive(:use_ssl=).with(true)
        expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        expect(http).to receive(:open_timeout=).with(60)
        azure_client2.send(:http, uri)
      end
    end

    context "when ssl validation is not skipped and the ca file is specified" do
      let(:azure_client2) {
        Bosh::AzureCloud::AzureClient2.new(
          mock_cloud_options["properties"]["azure"].merge!({
            "environment" => "AzureStack",
            "azure_stack" => {
              "domain"              => azure_stack_domain,
              "resource"            => "fake-resource",
              "skip_ssl_validation" => false,
              "ca_cert"             => "fake-ca-cert-content"
            }
          }),
          logger
        )
      }
      let(:ca_file_path) { "/var/vcap/jobs/azure_cpi/config/azure_stack_ca_cert.pem" }

      context "when the uri doesn't contain the AzureStack domain" do
        let(:uri) { URI("https://fake-host") }

        it "should not use the mode VERIFY_NONE, and the ca file is not configured" do
          expect(http).to receive(:use_ssl=).with(true)
          expect(http).not_to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
          expect(http).not_to receive(:ca_file=).with(ca_file_path)
          expect(http).to receive(:open_timeout=).with(60)
          azure_client2.send(:http, uri)
        end
      end

      context "when the uri contains the AzureStack domain" do
        let(:uri) { URI("https://#{azure_stack_domain}") }

        it "should not use the mode VERIFY_NONE, and the ca file is configured" do
          expect(http).to receive(:use_ssl=).with(true)
          expect(http).not_to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
          expect(http).to receive(:ca_file=).with(ca_file_path)
          expect(http).to receive(:open_timeout=).with(60)
          azure_client2.send(:http, uri)
        end
      end
    end
  end
end
