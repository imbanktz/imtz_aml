//= require active_admin/base
// #### Hour meter
document.addEventListener('DOMContentLoaded', function() {
    // Real-time preview for hour meter form
    const assetSelect = document.getElementById('asset-select');
    const meterInput = document.getElementById('hour-meter-input');
    const typeSelect = document.querySelector('.type-select');
    const previewAsset = document.getElementById('preview-asset');
    const previewReading = document.getElementById('preview-reading');
    const previewType = document.getElementById('preview-type');
    
    function updatePreview() {
	if (previewAsset && assetSelect) {
	    const selectedOption = assetSelect.options[assetSelect.selectedIndex];
	    previewAsset.textContent = selectedOption ? selectedOption.text.split(' - ')[0] : 'Not selected';
	}
	
	if (previewReading && meterInput) {
	    const value = parseFloat(meterInput.value) || 0;
	    previewReading.textContent = `${value.toLocaleString()} hours`;
	}
	
	if (previewType && typeSelect) {
	    const selectedOption = typeSelect.options[typeSelect.selectedIndex];
	    previewType.textContent = selectedOption ? selectedOption.text.replace(/[^a-zA-Z\s]/g, '').trim() : 'Regular';
	}
    }
    
    if (assetSelect) assetSelect.addEventListener('change', updatePreview);
    if (meterInput) meterInput.addEventListener('input', updatePreview);
    if (typeSelect) typeSelect.addEventListener('change', updatePreview);
    
    // Initial preview
    updatePreview();
});
// #### 
