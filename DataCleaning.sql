-- Data Cleaning

SELECT *
FROM NashvilleHousing


-- Standardise Date Format

SELECT SaleDate, CONVERT(date, SaleDate)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date


-- Populate Property Address Data

-- Notice that if the ParcelID is the same between rows then so is the PropertyAddress
SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Can populate NULL PropertyAddress entries by comparing different rows in the same table
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]  -- Ensures comparing different rows
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-- Breaking up address into individual columns (Address, City, State)

-- Property Address

SELECT PropertyAddress
FROM NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

-- Owner Address

SELECT OwnerAddress
FROM NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 3)
	, PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2)
	, PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 3)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 2)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ', ', '.'), 1)

SELECT *
FROM NashvilleHousing


-- Change Y and N to Yes and No in 'Sold as Vacant' field

SELECT SoldAsVacant, COUNT(SoldAsVacant) AS Count
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY Count

SELECT SoldAsVacant
	, CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	  END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
					 WHEN SoldAsVacant = 'Y' THEN 'Yes'
					 WHEN SoldAsVacant = 'N' THEN 'No'
					 ELSE SoldAsVacant
				   END


-- Remove Duplicates (we use delete here but not standard practice to delete from the source data)

WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (
		  PARTITION BY ParcelID,
					   PropertyAddress,
					   SaleDate,
					   SalePrice,
					   LegalReference
					   ORDER BY 
						UniqueID
		  ) row_num
FROM NashvilleHousing
--ORDER BY ParcelID
)
-- DELETE
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

SELECT *
FROM NashvilleHousing


-- Delete Unused Columns

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict