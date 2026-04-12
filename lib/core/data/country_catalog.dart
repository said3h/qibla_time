class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

const countryCatalog = <CountryOption>[
  CountryOption(code: 'AF', name: 'Afghanistan'),
  CountryOption(code: 'AL', name: 'Albania'),
  CountryOption(code: 'DZ', name: 'Algeria'),
  CountryOption(code: 'AR', name: 'Argentina'),
  CountryOption(code: 'AU', name: 'Australia'),
  CountryOption(code: 'AT', name: 'Austria'),
  CountryOption(code: 'AZ', name: 'Azerbaijan'),
  CountryOption(code: 'BH', name: 'Bahrain'),
  CountryOption(code: 'BD', name: 'Bangladesh'),
  CountryOption(code: 'BE', name: 'Belgium'),
  CountryOption(code: 'BA', name: 'Bosnia and Herzegovina'),
  CountryOption(code: 'BR', name: 'Brazil'),
  CountryOption(code: 'BN', name: 'Brunei'),
  CountryOption(code: 'BG', name: 'Bulgaria'),
  CountryOption(code: 'CA', name: 'Canada'),
  CountryOption(code: 'CL', name: 'Chile'),
  CountryOption(code: 'CN', name: 'China'),
  CountryOption(code: 'CO', name: 'Colombia'),
  CountryOption(code: 'HR', name: 'Croatia'),
  CountryOption(code: 'CZ', name: 'Czech Republic'),
  CountryOption(code: 'DK', name: 'Denmark'),
  CountryOption(code: 'EG', name: 'Egypt'),
  CountryOption(code: 'EE', name: 'Estonia'),
  CountryOption(code: 'ET', name: 'Ethiopia'),
  CountryOption(code: 'FI', name: 'Finland'),
  CountryOption(code: 'FR', name: 'France'),
  CountryOption(code: 'GE', name: 'Georgia'),
  CountryOption(code: 'DE', name: 'Germany'),
  CountryOption(code: 'GH', name: 'Ghana'),
  CountryOption(code: 'GR', name: 'Greece'),
  CountryOption(code: 'HU', name: 'Hungary'),
  CountryOption(code: 'IS', name: 'Iceland'),
  CountryOption(code: 'IN', name: 'India'),
  CountryOption(code: 'ID', name: 'Indonesia'),
  CountryOption(code: 'IR', name: 'Iran'),
  CountryOption(code: 'IQ', name: 'Iraq'),
  CountryOption(code: 'IE', name: 'Ireland'),
  CountryOption(code: 'IT', name: 'Italy'),
  CountryOption(code: 'JP', name: 'Japan'),
  CountryOption(code: 'JO', name: 'Jordan'),
  CountryOption(code: 'KZ', name: 'Kazakhstan'),
  CountryOption(code: 'KE', name: 'Kenya'),
  CountryOption(code: 'XK', name: 'Kosovo'),
  CountryOption(code: 'KW', name: 'Kuwait'),
  CountryOption(code: 'KG', name: 'Kyrgyzstan'),
  CountryOption(code: 'LB', name: 'Lebanon'),
  CountryOption(code: 'LY', name: 'Libya'),
  CountryOption(code: 'LU', name: 'Luxembourg'),
  CountryOption(code: 'MY', name: 'Malaysia'),
  CountryOption(code: 'MV', name: 'Maldives'),
  CountryOption(code: 'ML', name: 'Mali'),
  CountryOption(code: 'MR', name: 'Mauritania'),
  CountryOption(code: 'MX', name: 'Mexico'),
  CountryOption(code: 'MA', name: 'Morocco'),
  CountryOption(code: 'NL', name: 'Netherlands'),
  CountryOption(code: 'NZ', name: 'New Zealand'),
  CountryOption(code: 'NG', name: 'Nigeria'),
  CountryOption(code: 'MK', name: 'North Macedonia'),
  CountryOption(code: 'NO', name: 'Norway'),
  CountryOption(code: 'OM', name: 'Oman'),
  CountryOption(code: 'PK', name: 'Pakistan'),
  CountryOption(code: 'PS', name: 'Palestine'),
  CountryOption(code: 'PE', name: 'Peru'),
  CountryOption(code: 'PH', name: 'Philippines'),
  CountryOption(code: 'PL', name: 'Poland'),
  CountryOption(code: 'PT', name: 'Portugal'),
  CountryOption(code: 'QA', name: 'Qatar'),
  CountryOption(code: 'RO', name: 'Romania'),
  CountryOption(code: 'RU', name: 'Russia'),
  CountryOption(code: 'SA', name: 'Saudi Arabia'),
  CountryOption(code: 'SN', name: 'Senegal'),
  CountryOption(code: 'RS', name: 'Serbia'),
  CountryOption(code: 'SG', name: 'Singapore'),
  CountryOption(code: 'SK', name: 'Slovakia'),
  CountryOption(code: 'SI', name: 'Slovenia'),
  CountryOption(code: 'SO', name: 'Somalia'),
  CountryOption(code: 'ZA', name: 'South Africa'),
  CountryOption(code: 'KR', name: 'South Korea'),
  CountryOption(code: 'ES', name: 'Spain'),
  CountryOption(code: 'LK', name: 'Sri Lanka'),
  CountryOption(code: 'SD', name: 'Sudan'),
  CountryOption(code: 'SE', name: 'Sweden'),
  CountryOption(code: 'CH', name: 'Switzerland'),
  CountryOption(code: 'SY', name: 'Syria'),
  CountryOption(code: 'TW', name: 'Taiwan'),
  CountryOption(code: 'TJ', name: 'Tajikistan'),
  CountryOption(code: 'TZ', name: 'Tanzania'),
  CountryOption(code: 'TH', name: 'Thailand'),
  CountryOption(code: 'TN', name: 'Tunisia'),
  CountryOption(code: 'TR', name: 'Turkey'),
  CountryOption(code: 'TM', name: 'Turkmenistan'),
  CountryOption(code: 'UG', name: 'Uganda'),
  CountryOption(code: 'UA', name: 'Ukraine'),
  CountryOption(code: 'AE', name: 'United Arab Emirates'),
  CountryOption(code: 'GB', name: 'United Kingdom'),
  CountryOption(code: 'US', name: 'United States'),
  CountryOption(code: 'UZ', name: 'Uzbekistan'),
  CountryOption(code: 'VE', name: 'Venezuela'),
  CountryOption(code: 'VN', name: 'Vietnam'),
  CountryOption(code: 'YE', name: 'Yemen'),
];

CountryOption? findCountryOption(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  final normalized = code.trim().toUpperCase();
  for (final country in countryCatalog) {
    if (country.code == normalized) {
      return country;
    }
  }
  return null;
}

String countryFlagEmoji(String? code) {
  if (code == null || code.length != 2) {
    return '';
  }
  final normalized = code.toUpperCase();
  final first = normalized.codeUnitAt(0);
  final second = normalized.codeUnitAt(1);
  if (first < 65 || first > 90 || second < 65 || second > 90) {
    return '';
  }
  return String.fromCharCode(first + 127397) +
      String.fromCharCode(second + 127397);
}
