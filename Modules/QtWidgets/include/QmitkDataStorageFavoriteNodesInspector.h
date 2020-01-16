/*============================================================================

The Medical Imaging Interaction Toolkit (MITK)

Copyright (c) German Cancer Research Center (DKFZ)
All rights reserved.

Use of this source code is governed by a 3-clause BSD license that can be
found in the LICENSE file.

============================================================================*/

#ifndef QMITKDATASTORAGEFAVORITENODESINSPECTOR_H
#define QMITKDATASTORAGEFAVORITENODESINSPECTOR_H

#include <MitkQtWidgetsExports.h>

#include <QmitkDataStorageListInspector.h>

#include "mitkNodePredicateProperty.h"

/*
* @brief This is an inspector that offers a simple list view on favorite nodes of a data storage.
*/
class MITKQTWIDGETS_EXPORT QmitkDataStorageFavoriteNodesInspector : public QmitkDataStorageListInspector
{
  Q_OBJECT

public:

  QmitkDataStorageFavoriteNodesInspector(QWidget* parent = nullptr);

  /**
  * @brief Overrides the corresponding function of QmitkAbstractDataStorageInspector:
  *        The custom favorite nodes predicate is added to the parameter predicate
  *        which results in a combined node predicate that always filters nodes according
  *        to their favorite-property-state.
  *
  * @param nodePredicate    A pointer to a node predicate.
  */
  void SetNodePredicate(mitk::NodePredicateBase* nodePredicate) override;

protected Q_SLOTS:

  void OnFavoriteNodesButtonClicked();

private:

  mitk::NodePredicateProperty::Pointer m_FavoriteNodeSelectionPredicate;

};

#endif // QMITKDATASTORAGEFAVORITENODESINSPECTOR_H
