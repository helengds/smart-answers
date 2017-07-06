require 'test_helper'

class ContentItemPublisherTest < ActiveSupport::TestCase
  setup do
    load_path = fixture_file('smart_answer_flows')
    SmartAnswer::FlowRegistry.stubs(:instance).returns(stub("Flow registry", find: @flow, load_path: load_path))
  end

  test 'sending item to content store' do
    draft_request = stub_request(:put, "https://publishing-api.test.gov.uk/v2/content/3e6f33b8-0723-4dd5-94a2-cab06f23a685")
    publishing_request = stub_request(:post, "https://publishing-api.test.gov.uk/v2/content/3e6f33b8-0723-4dd5-94a2-cab06f23a685/publish")

    presenter = FlowRegistrationPresenter.new(stub('flow', name: 'bridge-of-death', start_page_content_id: '3e6f33b8-0723-4dd5-94a2-cab06f23a685', external_related_links: nil))

    ContentItemPublisher.new.publish([presenter])

    assert_requested draft_request, times: 2
    assert_requested publishing_request, times: 2
  end

  context "#unpublish" do
    should 'send unpublish request to content store' do
      unpublish_url = 'https://publishing-api.test.gov.uk/v2/content/content-id/unpublish'
      unpublish_request = stub_request(:post, unpublish_url)

      ContentItemPublisher.new.unpublish('content-id')

      assert_requested unpublish_request
    end

    should 'raise exception if content_id has not been supplied' do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.unpublish(nil)
      end

      assert_equal "Content id has not been supplied", exception.message
    end
  end

  context "#publish_redirect" do
    setup do
      SecureRandom.stubs(:uuid).returns('content-id')
      create_url = 'https://publishing-api.test.gov.uk/v2/content/content-id'
      @create_request = stub_request(:put, create_url)
      publish_url = 'https://publishing-api.test.gov.uk/v2/content/content-id/publish'
      @publish_request = stub_request(:post, publish_url)
    end

    should 'send a redirect and publish request to publishing-api' do
      ContentItemPublisher.new.publish_redirect('/path', '/destination-path')

      assert_requested @create_request
      assert_requested @publish_request
    end

    should 'raise exception and not attempt publishing and router requests, when create request fails' do
      GdsApi::Response.any_instance.stubs(:code).returns(500)
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_redirect('/path', '/destination-path')
      end

      assert_equal "This content item has not been created", exception.message
      assert_requested @create_request
      assert_not_requested @publish_request
    end

    should 'raises exception if destination is not defined' do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_redirect('/path', nil)
      end

      assert_equal "The destination or path isn't defined", exception.message
    end

    should 'raises exception if path is not defined' do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_redirect(nil, '/destination-path')
      end

      assert_equal "The destination or path isn't defined", exception.message
    end
  end

  context "#remove_smart_answer_from_search" do
    should 'raise exception if base_path is not supplied' do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.remove_smart_answer_from_search(nil)
      end

      assert_equal "The base_path isn't supplied", exception.message
    end

    should 'send remove content request to rummager' do
      delete_url = 'https://rummager.test.gov.uk/content?link=/base-path'
      delete_request = stub_request(:delete, delete_url)

      ContentItemPublisher.new.remove_smart_answer_from_search('/base-path')

      assert_requested delete_request
    end
  end

  context "#reserve_path_for_publishing_app" do
    should 'raise exception if base_path is not supplied' do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.reserve_path_for_publishing_app(nil, "publisher")
      end

      assert_equal "The destination or path isn't supplied", exception.message
    end

    should 'raise exception if publishing_app is not supplied' do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.reserve_path_for_publishing_app("/base_path", nil)
      end

      assert_equal "The destination or path isn't supplied", exception.message
    end

    should 'send a base_path publishing_app reservation request' do
      reservation_url = 'https://publishing-api.test.gov.uk/paths//base_path'
      reservation_request = stub_request(:put, reservation_url)

      ContentItemPublisher.new.reserve_path_for_publishing_app('/base_path', 'publisher')

      assert_requested reservation_request
    end
  end

  context "#publish_transaction" do
    setup do
      SecureRandom.stubs(:uuid).returns('content-id')
      create_url = "https://publishing-api.test.gov.uk/v2/content/content-id"
      @create_request = stub_request(:put, create_url)
      publish_url = "https://publishing-api.test.gov.uk/v2/content/content-id/publish"
      @publish_request = stub_request(:post, publish_url)
    end

    should "raise exception if base_path is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_transaction(
          nil,
          publishing_app: "publisher",
          title: "Sample transaction title",
          content: "Sample transaction content",
          link: "https://smaple.gov.uk/path/to/somewhere"
        )
      end

      assert_equal "The base path isn't supplied", exception.message
    end

    should "raise exception if publishing_app is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_transaction(
          "/base-path",
          publishing_app: nil,
          title: "Sample transaction title",
          content: "Sample transaction content",
          link: "https://smaple.gov.uk/path/to/somewhere"
        )
      end

      assert_equal "The publishing_app isn't supplied", exception.message
    end

    should "raise exception if title is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_transaction(
          "/base-path",
          publishing_app: "publisher",
          title: nil,
          content: "Sample transaction content",
          link: "https://smaple.gov.uk/path/to/somewhere"
        )
      end

      assert_equal "The title isn't supplied", exception.message
    end

    should "raise exception if content is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_transaction(
          "/base-path",
          publishing_app: "publisher",
          title: "Sample transaction title",
          content: nil,
          link: "https://smaple.gov.uk/path/to/somewhere"
        )
      end

      assert_equal "The content isn't supplied", exception.message
    end

    should "raise exception if link is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_transaction(
          "/base-path",
          publishing_app: "publisher",
          title: "Sample transaction title",
          content: "Sample transaction content",
          link: nil
        )
      end

      assert_equal "The link isn't supplied", exception.message
    end

    should "send publish transaction request to publishing-api" do
      ContentItemPublisher.new.publish_transaction(
        "/base-path",
        publishing_app: "publisher",
        title: "Sample transaction title",
        content: "Sample transaction content",
        link: "https://smaple.gov.uk/path/to/somewhere"
      )

      assert_requested @create_request
      assert_requested @publish_request
    end

    should "raise exception and not attempt publishing transaction when create request fails" do
      GdsApi::Response.any_instance.stubs(:code).returns(500)
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_transaction(
          "/base-path",
          publishing_app: "publisher",
          title: "Sample transaction title",
          content: "Sample transaction content",
          link: "https://smaple.gov.uk/path/to/somewhere"
        )
      end

      assert_equal "This content item has not been created", exception.message
      assert_requested @create_request
      assert_not_requested @publish_request
    end
  end

  context "#publish_answer" do
    setup do
      SecureRandom.stubs(:uuid).returns('content-id')
      create_url = "https://publishing-api.test.gov.uk/v2/content/content-id"
      @create_request = stub_request(:put, create_url)
      publish_url = "https://publishing-api.test.gov.uk/v2/content/content-id/publish"
      @publish_request = stub_request(:post, publish_url)
    end

    should "send publish answer request to publishing-api" do
      ContentItemPublisher.new.publish_answer(
        "/base-path",
        publishing_app: "publisher",
        title: "Sample answer title",
        content: "Sample answer content"
      )

      assert_requested @create_request
      assert_requested @publish_request
    end

    should "raise exception and not attempt publishing answer when create request fails" do
      GdsApi::Response.any_instance.stubs(:code).returns(500)
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_answer(
          "/base-path",
          publishing_app: "publisher",
          title: "Sample answer title",
          content: "Sample answer content"
        )
      end

      assert_equal "This content item has not been created", exception.message
      assert_requested @create_request
      assert_not_requested @publish_request
    end

    should "raise exception if base_path is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_answer(
          nil,
          publishing_app: "publisher",
          title: "Sample answer title",
          content: "Sample answer content"
        )
      end

      assert_equal "The base path isn't supplied", exception.message
    end

    should "raise exception if publishing_app is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_answer(
          "/base-path",
          publishing_app: nil,
          title: "Sample answer title",
          content: "Sample answer content"
        )
      end

      assert_equal "The publishing_app isn't supplied", exception.message
    end

    should "raise exception if title is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_answer(
          "/base-path",
          publishing_app: "publisher",
          title: nil,
          content: "Sample answer content"
        )
      end

      assert_equal "The title isn't supplied", exception.message
    end

    should "raise exception if content is not supplied" do
      exception = assert_raises(RuntimeError) do
        ContentItemPublisher.new.publish_answer(
          "/base-path",
          publishing_app: "publisher",
          title: "Sample answer title",
          content: nil
        )
      end

      assert_equal "The content isn't supplied", exception.message
    end
  end
end
