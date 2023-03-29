SELECT * FROM NashvilleHousing

-- Formatting Date
SELECT SaleDateConverted, CONVERT(DATE, SaleDate) FROM NashvilleHousing
ALTER TABLE NashvilleHousing ADD SaleDateConverted DATE
UPDATE NashvilleHousing SET SaleDateConverted = CONVERT(DATE, SaleDate)

-- Populate Property Address Date
SELECT * FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT	NH01.ParcelID, NH01.PropertyAddress, NH02.ParcelID, NH02.PropertyAddress,
		ISNULL(NH01.PropertyAddress, NH02.PropertyAddress) AS PropertyAddressPopulated
FROM NashvilleHousing AS NH01
	JOIN NashvilleHousing AS NH02 ON 
		NH01.ParcelID = NH02.ParcelID
		AND NH01.[UniqueID ] <> NH02.[UniqueID ]
	WHERE NH01.PropertyAddress IS NULL

UPDATE NH01
SET PropertyAddress =  ISNULL(NH01.PropertyAddress, NH02.PropertyAddress) 
FROM NashvilleHousing AS NH01
	JOIN NashvilleHousing AS NH02 ON 
		NH01.ParcelID = NH02.ParcelID
		AND NH01.[UniqueID ] <> NH02.[UniqueID ]
	WHERE NH01.PropertyAddress IS NULL

-- Breaking down Property Address into Address and City
	-- Delimiter is Comma
SELECT PropertyAddress FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing ADD PropertySplitAddress VARCHAR(255)
UPDATE NashvilleHousing SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing ADD PropertySplitCity VARCHAR(255)
UPDATE NashvilleHousing SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT * FROM NashvilleHousing

-- Breaking Owner Address into Address, City, State
SELECT OwnerAddress FROM NashvilleHousing

-- PARSENAME looks for Periods and does not recognize Commas; 
	-- It goes backwards on a string:
	-- 1 Would give you the things after the last period
SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing ADD OwnerSplitAddress VARCHAR(255)
UPDATE NashvilleHousing SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing ADD OwnerSplitCity VARCHAR(255)
UPDATE NashvilleHousing SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing ADD OwnerSplitState VARCHAR(255)
UPDATE NashvilleHousing SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT * FROM NashvilleHousing

-- SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant),
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM NashvilleHousing
GROUP BY SoldAsVacant ORDER BY 2

UPDATE NashvilleHousing SET
	SoldAsVacant = 	
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END

SELECT SoldAsVacant, COUNT(SoldAsVacant)
	FROM NashvilleHousing
GROUP BY SoldAsVacant ORDER BY 2

-- Remove Duplicates using CTE
	-- We have same row even though the UniqueID is different.
	-- Remove them using RANK, DENSE_RANK or ROW_NUMBER
SELECT *, RANK() 
	OVER(PARTITION BY 
			ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY ParcelID) AS RowNumber
FROM NashvilleHousing
WHERE [UniqueID ] = 26110 OR [UniqueID ] = 27121
ORDER BY ParcelID

-- CTE with ROW_NUMBER
WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() 
	OVER(PARTITION BY 
			ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY UniqueID) AS RowNumber
FROM NashvilleHousing
)
SELECT * FROM RowNumCTE
WHERE RowNumber > 1
ORDER BY PropertyAddress

-- We ought to delete the 104 rows that are duplicates:
WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() 
	OVER(PARTITION BY 
			ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		ORDER BY UniqueID) AS RowNumber
FROM NashvilleHousing
)
DELETE FROM RowNumCTE 
WHERE RowNumber > 1

-- Delete TaxDistrict, PropertyAddress and OwnerAddress
ALTER TABLE NashvilleHousing 
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

-- Delete SaleDate
ALTER TABLE NashvilleHousing 
DROP COLUMN SaleDate

SELECT * FROM NashvilleHousing

-- The dataset is NOT completely clean but the usability of the dataset is increased.
	-- Certain columns such as Bedrooms, FullBath & HalfBath can only be filled using its Average, for example, which may not be efficient.
	-- Certain columns such as OwnerName cannot be filled at all from within this table only.
	-- It does not make sense to average the columns such as LandValue and BuildingValue to fill in for the Nulls.
-- The above approaches may make sense for Machine Learning Implementation to perhaps predict a variable.
-- However, it is advisable that other tables, if available, be utilized for additional information, that may help cleaning the data in a more sensible manner.