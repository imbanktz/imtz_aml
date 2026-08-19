
#### UAT
THETARAY_BASE_URL = "https://apps-tanzania-screening.imbank.thetaray.cloud"
API_TOKEN = "/security/accessToken"
API_TRANSACTION_SCREENING = "/screening/transaction/generic/check"
API_CUSTOMER_SCREENING = "/screening/customer/check"
TOKEN_ENDPOINT = '/security/accessToken'

# AMLOCK_SERVER_IP = "192.168.205.136"
AMLOCK_SOURCE_FILES = "/amlock/Tanzania/RMS/mxt_to_mt/rtgs_source_only"
AMLOCK_DESTINATION_FILES = "/amlock/Tanzania/RMS/input/Incoming_Files"
# AMLOCK_SOURCE_FILES = "/amlock/Tanzania/RMS/mxt_to_mt/source_files"
# AMLOCK_DESTINATION_FILES = "/amlock/Tanzania/RMS/mxt_to_mt/mt_converted"
AMLOCK_DESTINATION_FILES_FAILED = "/amlock/Tanzania/RMS/mxt_to_mt/failed"
AMLOCK_DESTINATION_FILES_ORIGINAL = "/amlock/Tanzania/RMS/mxt_to_mt/original"
# AMLOCK_USER_NAME = "amladm"
# AMLOCK_PASSWORD = "123qweASD!@#"



AMLOCK_SERVER_IP = ENV['AMLOCK_SERVER_IP'] || '192.168.205.136'
AMLOCK_USER_NAME = ENV['AMLOCK_USER_NAME'] || 'amladm'
AMLOCK_PASSWORD = ENV['AMLOCK_PASSWORD'] || '123qweASD!@#'
AMLOCK_SOURCE_FILES = ENV['AMLOCK_SOURCE_FILES'] || '/amlock/Tanzania/RMS/mxt_to_mt/rtgs_source_only'

# #### PROD 
