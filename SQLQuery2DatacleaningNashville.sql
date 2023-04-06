-- Let's have a look at the whole table 
--Select*
--From Nashville_housing

1---STANDARDISE DATA FORMAT

Select SaleDate, CONVERT(Date, SaleDate)
From Nashville_housing

UPDATE Nashville_housing
Set SaleDate = CONVERT(Date, SaleDate)

--When using the query above, it does not work properly so we will be using ALTER
ALTER TABLE Nashville_housing
ADD SalesDateConverted Date;

UPDATE  Nashville_housing
SET SalesDateConverted = CONVERT(Date, SaleDate)


--Let's go back and see if the new update will work
Select SalesDateConverted, CONVERT(Date, SaleDate)
From Nashville_housing


2---POPULATE PROPERTY ADDRESS DATA
Select *
From Nashville_housing

Select PropertyAddress
From Nashville_housing

Select*
from Nashville_housing
Where PropertyAddress is null

--Each ParcelID has it's own propertyadress so if there is any null in propertyadress it can be solved by looking at the duplicate ParcelID
Select*
From Nashville_housing
Order by ParcelID


--To solve the problem above, we have to do a self join 
Select*
From Nashville_housing AS N1
JOIN Nashville_housing AS N2
On N1.ParcelID = N2.ParcelID
AND N1.[UniqueID ] <> N2.[UniqueID ]


--Let's focus only on ParcelID and PropertyAddress
Select N1.ParcelID, N1.PropertyAddress, N2.ParcelID, N2.PropertyAddress
From Nashville_housing AS N1
JOIN Nashville_housing AS N2
On N1.ParcelID = N2.ParcelID
AND N1.[UniqueID ] <> N2.[UniqueID ]
Where N1.PropertyAddress is null

--In the case above, we noticed that the N1.propertyAddress is null and N2.propertyaddress has addresses. What we can do is to use 'ISNULL' to fill out N1.propertyaddress
Select N1.ParcelID, N1.PropertyAddress, N2.ParcelID, N2.PropertyAddress, ISNULL (N1.PropertyAddress, N2.PropertyAddress)
From Nashville_housing AS N1
JOIN Nashville_housing AS N2
On N1.ParcelID = N2.ParcelID
AND N1.[UniqueID ] <> N2.[UniqueID ]
Where N1.PropertyAddress is null

--Let's do the UPDATE. We do use the ALIAS in this case, otherwise it brings error
UPDATE N1
SET PropertyAddress = ISNULL (N1.PropertyAddress, N2.PropertyAddress)
From Nashville_housing AS N1
JOIN Nashville_housing AS N2
On N1.ParcelID = N2.ParcelID
AND N1.[UniqueID ] <> N2.[UniqueID ]
Where N1.PropertyAddress is null

--Verification if it works
Select N1.ParcelID, N1.PropertyAddress, N2.ParcelID, N2.PropertyAddress, ISNULL (N1.PropertyAddress, N2.PropertyAddress)
From Nashville_housing AS N1
JOIN Nashville_housing AS N2
On N1.ParcelID = N2.ParcelID
AND N1.[UniqueID ] <> N2.[UniqueID ]
Where N1.PropertyAddress is null



3-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMN (ADDRESS, CITY, STATE)

--Let's check the propertyAddress alone
Select PropertyAddress
From Nashville_housing

--Address is seperated by a delimiter, COMA in this case. We will be using Substring and Character index to have individial column
Select
SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress)) As Address
From Nashville_housing

--Let's get rid off the coma
Select
SUBSTRING (PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1) As Address
From Nashville_housing

--Let's have the city in a different column
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
FROM Nashville_housing

--Split the address
ALTER TABLE Nashville_housing
Add PropertySplitAddress Nvarchar(255);

Update Nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

--Split the city
ALTER TABLE Nashville_housing
Add PropertySplitCity Nvarchar(255);

Update Nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--Verification
Select*
From Nashville_housing


--Let's focus now on 'OwnerAddress' by seperating the address. We wll be using 'PARSENAME', in this case we will switch coma to period as it works only for period
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
From Nashville_housing

--The Address is in backwards (State, City and Address). We gonna switch the numbers (3,2,1)
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Nashville_housing


=--Let's update the Owner Address
ALTER TABLE Nashville_housing
Add OwnerSplitAddress Nvarchar(255);

Update Nashville_housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE Nashville_housing
Add OwnerSplitCity Nvarchar(255);

Update Nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE Nashville_housing
Add OwnerSplitState Nvarchar(255);

Update Nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


--Verification
Select*
From Nashville_housing

4- --CHANGE Y AND N TO YES AND NO IN 'SOLD AS VACANT' FIELD
Select DISTINCT (SoldASVacant), COUNT(SoldAsVacant) AS Count
From Nashville_housing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From Nashville_housing

--Let's do the update
Update Nashville_housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


--Verification

Select DISTINCT (SoldASVacant), COUNT(SoldAsVacant) AS Count
From Nashville_housing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant

Select*
From Nashville_housing

5- --REMOVE DUPLICATES

Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Nashville_housing
 

 --We noticed that row_num has an issue with number 2 in it. Let's use the CTE in this case
 WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Nashville_housing)

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

--Let's delete the duplicates
 WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Nashville_housing)

DELETE
From RowNumCTE
Where row_num > 1
---Order by PropertyAddress

--Verification 
 WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Nashville_housing)

SELECT*
From RowNumCTE
Where row_num > 1


6-- DELETE UNUSED COLUMNS
SELECT*
FROM Nashville_housing


ALTER TABLE Nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

 