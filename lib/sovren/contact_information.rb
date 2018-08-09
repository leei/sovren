module Sovren
  class ContactInformation
    attr_accessor :first_name, :middle_name, :last_name, :aristocratic_title, :form_of_address, :generation, :qualification, :address_line_1, :address_line_2, :city, :state, :country, :postal_code, :phone_numbers, :email_addresses, :websites

    def self.parse(contact_information)
      return nil if contact_information.nil?
      result = self.new
      result.first_name = contact_information.css('PersonName GivenName').collect(&:text).join(" ")
      result.middle_name = contact_information.css('PersonName MiddleName').collect(&:text).join(" ")
      result.last_name = contact_information.css('PersonName FamilyName').collect(&:text).join(" ")
      result.aristocratic_title = contact_information.css('PersonName Affix[type=aristocraticTitle]').collect(&:text).join(" ")
      result.form_of_address = contact_information.css('PersonName Affix[type=formOfAddress]').collect(&:text).join(" ")
      result.generation = contact_information.css('PersonName Affix[type=generation]').collect(&:text).join(" ")
      result.qualification = contact_information.css('PersonName Affix[type=qualification]').collect(&:text).join(" ")

      address = contact_information.css('PostalAddress DeliveryAddress AddressLine').collect(&:text)
      result.address_line_1 = address[0] if address.length > 0
      result.address_line_2 = address[1] if address.length > 1
      result.city = contact_information.css('PostalAddress').first.css('Municipality').text rescue nil
      result.state = contact_information.css('PostalAddress').first.css('Region').text rescue nil
      result.postal_code = contact_information.css('PostalAddress').first.css('PostalCode').text rescue nil
      result.country = contact_information.css('PostalAddress').first.css('CountryCode').text rescue nil

      result.phone_numbers = []
      mobile_phones = contact_information.css('Mobile FormattedNumber').map { |m| { type: 'mobile', number: m.text } } rescue []
      fax_phones = contact_information.css('Fax FormattedNumber').map { |m| { type: 'fax', number: m.text } } rescue []

      other_phone_nodes = contact_information.css('ContactMethod').select { |node| node.css('Telephone').present? } rescue []
      other_phones = parse_other_phone_types(other_phone_nodes)

      result.phone_numbers.concat(mobile_phones)
      result.phone_numbers.concat(fax_phones)
      result.phone_numbers.concat(other_phones)

      result.websites = contact_information.css('InternetWebAddress').map(&:text) rescue nil
      result.email_addresses = contact_information.css('InternetEmailAddress').map(&:text) rescue nil

      result
    end

    def self.work_phone?(node)
      node.css('Location')&.text == 'office'
    end

    def self.formatted_number_from_node(node)
      node.css('FormattedNumber')&.text
    end

    def self.parse_other_phone_types(phone_nodes)
      phone_nodes.map do |node|
        if work_phone?(node)
          { type: 'work', number: formatted_number_from_node(node) }
        else
          { type: 'home', number: formatted_number_from_node(node) }
        end
      end
    end
  end
end
