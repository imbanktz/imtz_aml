#
#
# Copyright (c) 2025 
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @package  MX to MT covnerter project
# @author abdimuna, abdillah.muna@imbank.co.tz | abdimuna1@gmail.com
# @Company  I&M BANK 
# @description SFT file handler, upload and download remote files
# @license  private
# @version  0.0.1:
# @usage  Use ruby convention, when handling this code
##/

class RemoteFileService
  def initialize(host: nil, username: nil, password: nil)
    @host = host || ENV['REMOTE_HOST'] || AMLOCK_SERVER_IP
    @username = username || ENV['REMOTE_USERNAME'] || AMLOCK_USER_NAME
    @password = password || ENV['REMOTE_PASSWORD'] || AMLOCK_PASSWORD
  end

  def list_rtgs_files(remote_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.dir.entries(remote_path).select do |entry|
        entry.file? && entry.name.match?(/\.(txt|mt103|rtgs)$/i)
      end
    end
  rescue Net::SFTP::StatusException => e
    Rails.logger.error "Failed to list files: #{e.message}"
    []
  end

  def download_file(remote_path, local_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.download!(remote_path, local_path)
      true
    end
  rescue Net::SFTP::StatusException => e
    Rails.logger.error "Failed to download #{remote_path}: #{e.message}"
    false
  end

  def delete_remote_file(remote_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.remove!(remote_path)
      true
    end
  rescue Net::SFTP::StatusException => e
    Rails.logger.error "Failed to delete #{remote_path}: #{e.message}"
    false
  end

  def move_file(remote_path, destination_path)
    Net::SFTP.start(@host, @username, password: @password) do |sftp|
      sftp.rename!(remote_path, destination_path)
      true
    end
  rescue Net::SFTP::StatusException => e
    Rails.logger.error "Failed to move #{remote_path}: #{e.message}"
    false
  end
end
