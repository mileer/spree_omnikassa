require 'spec_helper'

describe "Checkout", js: true do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  let!(:omnikassa_payment_method) { create(:omnikassa_payment_method) }

  before do
    reset_spree_preferences do |config|
      config.currency = "EUR"
      config.omnikassa_url = 'https://payment-webinit.simu.omnikassa.rabobank.nl/paymentServlet'
      config.omnikassa_merchant_id = '002020000000001'
      config.omnikassa_secret_key = '002020000000001_KEY1'
      config.omnikassa_key_version = '1'
      random_prefix = (0...8).map { ('a'..'z').to_a[rand(26)] }.join
      config.omnikassa_transaction_reference_prefix = "SPROMNI#{random_prefix}"
    end
  end

  describe 'pay with omnikassa' do
    before do
      order = OrderWalkthrough.up_to(:delivery)
      user = create(:user)
      order.user = user
      order.update!

      Spree::CheckoutController.any_instance.stub(:current_order => order)
      Spree::CheckoutController.any_instance.stub(:try_spree_current_user => user)
    end

    it 'redirects to omnikassa' do
      goto_omnikassa

      # TODO: check: Is this omnikassa?
    end

    it 'success after omnikassa' do
      goto_omnikassa
      do_omnikassa_ideal_payment #TODO: Shall I mock this?

      # TODO: check: Is this the success return page?
    end
  end
end


def goto_omnikassa
  visit spree.checkout_state_path(:payment)
  choose('Omnikassa')
  click_button "Save and Continue"
  click_button "Place"
end

def do_omnikassa_ideal_payment
  first('.paymentmeanbutton:nth-child(2) > a').click
  click_button "Akkoord"
  click_button "Bevestig de transactie"
  click_link "Verder"

  # Accept SSL warning
  a = page.driver.browser.switch_to.alert
  a.accept
end
