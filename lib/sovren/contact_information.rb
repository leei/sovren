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
      mobile_phones = contact_information.css('Mobile FormattedNumber').map { |m| { type: 'mobile', number: m.text } } rescue nil
      fax_phones = contact_information.css('Fax FormattedNumber').map { |m| { type: 'fax', number: m.text } } rescue nil

      other_phone_nodes = contact_information.css('ContactMethod')&.select { |node| node.css('Telephone').present? }
      home_phones = parse_phones_of_type('home', other_phone_nodes) if other_phone_nodes.present?
      work_phones = parse_phones_of_type('office', other_phone_nodes) if other_phone_nodes.present?

      result.phone_numbers.concat(mobile_phones) if mobile_phones.present?
      result.phone_numbers.concat(fax_phones) if fax_phones.present?
      result.phone_numbers.concat(home_phones) if home_phones.present?
      result.phone_numbers.concat(work_phones) if work_phones.present?

      result.websites = contact_information.css('InternetWebAddress').map(&:text) rescue nil
      result.email_addresses = contact_information.css('InternetEmailAddress').map(&:text) rescue nil

      result
    end

    def self.parse_phones_of_type(type, phone_nodes)
      type_mappings = {
        home: 'home',
        office: 'work'
      }
      matching_phone_nodes = phone_nodes.select { |node| node.css('Location')&.text == type }
      number_nodes = matching_phone_nodes.map { |node| node.css('FormattedNumber') }
      v3_type = type_mappings[type.to_sym]
      number_nodes.map { |n| { type: v3_type, number: n.text } }
    end
  end
end
