# Force the latest version of chromedriver using the webdriver gem
require 'webdrivers/chromedriver'

if ENV['CI']
  ::Webdrivers.logger.level = :DEBUG
  ::Webdrivers::Chromedriver.update
end

def register_chrome_headless(language, name: :"chrome_headless_#{language}")
  Capybara.register_driver name do |app|
    options = Selenium::WebDriver::Chrome::Options.new

    if ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_TESTING_NO_HEADLESS'])
      # Maximize the window however large the available space is
      options.add_argument('--start-maximized')
      # Open dev tools for quick access
      options.add_argument('--auto-open-devtools-for-tabs')
    else
      options.add_argument('--window-size=1920,1080')
      options.add_argument('--headless')
      options.add_argument('--disable-gpu')
    end

    options.add_argument("--remote-debugging-port=9222")

    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-popup-blocking')
    options.add_argument("--lang=#{language}")

    options.add_preference(:download,
                           directory_upgrade: true,
                           prompt_for_download: false,
                           default_directory: DownloadedFile::PATH.to_s)

    options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      loggingPrefs: { browser: 'ALL' }
    )

    yield(options, capabilities) if block_given?

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 180
    client.open_timeout = 180

    driver = Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      desired_capabilities: capabilities,
      http_client: client,
      options: options
    )

    # Enable file downloads in headless mode
    # https://bugs.chromium.org/p/chromium/issues/detail?id=696481
    bridge = driver.browser.send :bridge

    bridge.http.call :post,
                     "/session/#{bridge.session_id}/chromium/send_command",
                     cmd: 'Page.setDownloadBehavior',
                     params: { behavior: 'allow', downloadPath: DownloadedFile::PATH.to_s }

    driver
  end

  Capybara::Screenshot.register_driver(name) do |driver, path|
    driver.browser.save_screenshot(path)
  end
end

register_chrome_headless 'en'
# Register german locale for custom field decimal test
register_chrome_headless 'de'

# Register mocking proxy driver
register_chrome_headless 'en', name: :headless_chrome_billy do |options, capabilities|
  options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")
  options.add_argument('--proxy-bypass-list=127.0.0.1;localhost')

  capabilities[:acceptInsecureCerts] = true
end

