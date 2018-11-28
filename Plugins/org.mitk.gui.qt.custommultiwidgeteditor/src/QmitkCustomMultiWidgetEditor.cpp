/*===================================================================

The Medical Imaging Interaction Toolkit (MITK)

Copyright (c) German Cancer Research Center,
Division of Medical Image Computing.
All rights reserved.

This software is distributed WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.

See LICENSE.txt or http://www.mitk.org for details.

===================================================================*/

#include "QmitkCustomMultiWidgetEditor.h"

#include <berryIPreferencesService.h>
#include <berryIPreferences.h>
#include <berryIWorkbenchPage.h>
#include <berryIWorkbenchPartConstants.h>
#include <berryUIException.h>

// custom multi widget editor plugin
#include "QmitkMultiWidgetDecorationManager.h"

// mitk qt widgets module
#include <QmitkCustomMultiWidget.h>
#include <QmitkInteractionSchemeToolBar.h>
#include <QmitkMultiWidgetConfigurationToolBar.h>

const QString QmitkCustomMultiWidgetEditor::EDITOR_ID = "org.mitk.editors.custommultiwidget";

class QmitkCustomMultiWidgetEditor::Impl final
{

public:

  Impl();
  ~Impl();

  QmitkCustomMultiWidget* m_CustomMultiWidget;
  QmitkInteractionSchemeToolBar* m_InteractionSchemeToolBar;
  QmitkMultiWidgetConfigurationToolBar* m_ConfigurationToolBar;

  std::unique_ptr<QmitkMultiWidgetDecorationManager> m_MultiWidgetDecorationManager;
};

QmitkCustomMultiWidgetEditor::Impl::Impl()
  : m_CustomMultiWidget(nullptr)
  , m_InteractionSchemeToolBar(nullptr)
  , m_ConfigurationToolBar(nullptr)
{
  // nothing here
}

QmitkCustomMultiWidgetEditor::Impl::~Impl()
{
  // nothing here
}

//////////////////////////////////////////////////////////////////////////
// QmitkCustomMultiWidgetEditor
//////////////////////////////////////////////////////////////////////////
QmitkCustomMultiWidgetEditor::QmitkCustomMultiWidgetEditor()
  : m_Impl(new Impl())
{
  // nothing here
}

QmitkCustomMultiWidgetEditor::~QmitkCustomMultiWidgetEditor()
{
  // nothing here
}

QmitkRenderWindow* QmitkCustomMultiWidgetEditor::GetActiveQmitkRenderWindow() const
{
  if (nullptr != m_Impl->m_CustomMultiWidget)
  {
    auto activeRenderWindowWidget = m_Impl->m_CustomMultiWidget->GetActiveRenderWindowWidget();
    if (nullptr != activeRenderWindowWidget)
    {
      return activeRenderWindowWidget->GetRenderWindow();
    }
  }

  return nullptr;
}

QHash<QString, QmitkRenderWindow*> QmitkCustomMultiWidgetEditor::GetQmitkRenderWindows() const
{
  QHash<QString, QmitkRenderWindow*> result;
  if (nullptr == m_Impl->m_CustomMultiWidget)
  {
    return result;
  }

  result = m_Impl->m_CustomMultiWidget->GetRenderWindows();
  return result;
}

QmitkRenderWindow* QmitkCustomMultiWidgetEditor::GetQmitkRenderWindow(const QString& id) const
{
  if (nullptr == m_Impl->m_CustomMultiWidget)
  {
    return nullptr;
  }

  return m_Impl->m_CustomMultiWidget->GetRenderWindow(id);
}

mitk::Point3D QmitkCustomMultiWidgetEditor::GetSelectedPosition(const QString& id) const
{
  if (nullptr == m_Impl->m_CustomMultiWidget)
  {
    return mitk::Point3D();
  }

  return m_Impl->m_CustomMultiWidget->GetSelectedPosition(id);
}

void QmitkCustomMultiWidgetEditor::SetSelectedPosition(const mitk::Point3D& pos, const QString& id)
{
  if (nullptr != m_Impl->m_CustomMultiWidget)
  {
    m_Impl->m_CustomMultiWidget->SetSelectedPosition(id, pos);
  }
}

void QmitkCustomMultiWidgetEditor::EnableDecorations(bool enable, const QStringList& decorations)
{
  m_Impl->m_MultiWidgetDecorationManager->ShowDecorations(enable, decorations);
}

bool QmitkCustomMultiWidgetEditor::IsDecorationEnabled(const QString& decoration) const
{
  return m_Impl->m_MultiWidgetDecorationManager->IsDecorationVisible(decoration);
}

QStringList QmitkCustomMultiWidgetEditor::GetDecorations() const
{
  return m_Impl->m_MultiWidgetDecorationManager->GetDecorations();
}

QmitkCustomMultiWidget* QmitkCustomMultiWidgetEditor::GetCustomMultiWidget()
{
  return m_Impl->m_CustomMultiWidget;
}

void QmitkCustomMultiWidgetEditor::OnLayoutSet(int row, int column)
{
  m_Impl->m_CustomMultiWidget->ResetLayout(row, column);
  FirePropertyChange(berry::IWorkbenchPartConstants::PROP_INPUT);
}

void QmitkCustomMultiWidgetEditor::OnSynchronize(bool synchronized)
{
  m_Impl->m_CustomMultiWidget->Synchronize(synchronized);
}

//////////////////////////////////////////////////////////////////////////
// PRIVATE
//////////////////////////////////////////////////////////////////////////
void QmitkCustomMultiWidgetEditor::SetFocus()
{
  if (nullptr != m_Impl->m_CustomMultiWidget)
  {
    m_Impl->m_CustomMultiWidget->setFocus();
  }
}

void QmitkCustomMultiWidgetEditor::CreateQtPartControl(QWidget* parent)
{
  if (nullptr == m_Impl->m_CustomMultiWidget)
  {
    QHBoxLayout* layout = new QHBoxLayout(parent);
    layout->setContentsMargins(0, 0, 0, 0);

    berry::IBerryPreferences* preferences = dynamic_cast<berry::IBerryPreferences*>(GetPreferences().GetPointer());
    mitk::BaseRenderer::RenderingMode::Type renderingMode = static_cast<mitk::BaseRenderer::RenderingMode::Type>(preferences->GetInt("Rendering Mode", 0));

    m_Impl->m_CustomMultiWidget = new QmitkCustomMultiWidget(parent, 0, 0, renderingMode);

    // create left toolbar: interaction scheme toolbar to switch how the render window navigation behaves
    if (nullptr == m_Impl->m_InteractionSchemeToolBar)
    {
      m_Impl->m_InteractionSchemeToolBar = new QmitkInteractionSchemeToolBar(parent);
      layout->addWidget(m_Impl->m_InteractionSchemeToolBar);
    }
    m_Impl->m_InteractionSchemeToolBar->SetInteractionEventHandler(m_Impl->m_CustomMultiWidget->GetInteractionEventHandler());

    // add center widget: the custom multi widget
    layout->addWidget(m_Impl->m_CustomMultiWidget);

    m_Impl->m_CustomMultiWidget->SetDataStorage(GetDataStorage());
    m_Impl->m_CustomMultiWidget->InitializeRenderWindowWidgets();

    // create right toolbar: configuration toolbar to change the render window widget layout
    if (nullptr == m_Impl->m_ConfigurationToolBar)
    {
      m_Impl->m_ConfigurationToolBar = new QmitkMultiWidgetConfigurationToolBar(m_Impl->m_CustomMultiWidget);
      layout->addWidget(m_Impl->m_ConfigurationToolBar);
    }

    connect(m_Impl->m_ConfigurationToolBar, &QmitkMultiWidgetConfigurationToolBar::LayoutSet, this, &QmitkCustomMultiWidgetEditor::OnLayoutSet);
    connect(m_Impl->m_ConfigurationToolBar, &QmitkMultiWidgetConfigurationToolBar::Synchronized, this, &QmitkCustomMultiWidgetEditor::OnSynchronize);

    m_Impl->m_MultiWidgetDecorationManager = std::make_unique<QmitkMultiWidgetDecorationManager>(m_Impl->m_CustomMultiWidget);

    OnPreferencesChanged(preferences);
  }
}

void QmitkCustomMultiWidgetEditor::OnPreferencesChanged(const berry::IBerryPreferences* preferences)
{
  if (m_Impl->m_CustomMultiWidget->GetRenderWindowWidgets().empty())
  {
    return;
  }

  // update decoration preferences
  m_Impl->m_MultiWidgetDecorationManager->DecorationPreferencesChanged(preferences);

  // zooming and panning preferences
  bool constrainedZooming = preferences->GetBool("Use constrained zooming and panning", true);
  mitk::RenderingManager::GetInstance()->SetConstrainedPanningZooming(constrainedZooming);

  mitk::RenderingManager::GetInstance()->InitializeViewsByBoundingObjects(GetDataStorage());
  mitk::RenderingManager::GetInstance()->RequestUpdateAll();
}
